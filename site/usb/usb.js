// Waaiya: the WebUSB side of the "set up from a computer" page: finds the phone's ADB interface and moves bytes.
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// ADB over USB is a vendor interface (class 0xff, subclass 0x42, protocol 1) with one bulk endpoint each way. A
// message is written as two transfers (the 24-byte header, then the data), as the adb host does.

export const ADB_FILTER = { classCode: 0xff, subclassCode: 0x42, protocolCode: 0x01 };

export const supported = () => typeof navigator !== "undefined" && !!navigator.usb;

function findAdb(device) {
  for (const conf of device.configurations) {
    for (const intf of conf.interfaces) {
      for (const alt of intf.alternates) {
        if (alt.interfaceClass === ADB_FILTER.classCode && alt.interfaceSubclass === ADB_FILTER.subclassCode &&
            alt.interfaceProtocol === ADB_FILTER.protocolCode) {
          const ep = (dir) => alt.endpoints.find((e) => e.direction === dir && e.type === "bulk");
          return { conf, intf, alt, in: ep("in"), out: ep("out") };
        }
      }
    }
  }
  return null;
}

export class UsbError extends Error {
  constructor(kind, message) { super(message); this.kind = kind; }
}

export class UsbTransport {
  /** Asks the browser for the phone (its chooser), or takes one this page was allowed before. */
  static async pick({ again = false } = {}) {
    if (!supported()) throw new UsbError("unsupported", "WebUSB is not available in this browser");
    if (again) {
      const known = (await navigator.usb.getDevices()).filter(findAdb);
      if (known.length === 1) return known[0];
    }
    try {
      return await navigator.usb.requestDevice({ filters: [ADB_FILTER] });
    } catch (e) {
      // NotFoundError: the chooser was closed, or no phone with USB debugging on was listed
      throw new UsbError("none", e.message);
    }
  }

  static async open(device) {
    const a = findAdb(device);
    if (!a || !a.in || !a.out) throw new UsbError("noadb", "no ADB interface on this device");
    try {
      await device.open();
    } catch (e) {
      // Linux without a udev rule for the phone, or Windows with a driver that is not WinUSB
      throw new UsbError("access", e.message);
    }
    try {
      if (!device.configuration || device.configuration.configurationValue !== a.conf.configurationValue)
        await device.selectConfiguration(a.conf.configurationValue);
      await device.claimInterface(a.intf.interfaceNumber);
      if (a.alt.alternateSetting) await device.selectAlternateInterface(a.intf.interfaceNumber, a.alt.alternateSetting);
    } catch (e) {
      await device.close().catch(() => {});
      // another program holds the phone: an adb server, Android Studio, a phone manager
      throw new UsbError("busy", e.message);
    }
    return new UsbTransport(device, a);
  }

  constructor(device, a) {
    this.device = device;
    this.a = a;
    this.inEp = a.in.endpointNumber;
    this.outEp = a.out.endpointNumber;
    this.packet = a.out.packetSize || 512;
    this.inPacket = a.in.packetSize || 512;
    this.pending = new Uint8Array(0);
  }

  async write(data) {
    const r = await this.device.transferOut(this.outEp, data);
    if (r.status !== "ok") throw new UsbError("io", "write: " + r.status);
    // a transfer that fills its last packet needs an empty packet after it, or the phone waits for more
    if (data.length && data.length % this.packet === 0) await this.device.transferOut(this.outEp, new Uint8Array(0));
  }

  async read(n) {
    while (this.pending.length < n) {
      // whole packets: asking for less than the phone sends in a packet is an overflow error on some hosts
      const want = Math.ceil((n - this.pending.length) / this.inPacket) * this.inPacket;
      const r = await this.device.transferIn(this.inEp, want);
      if (r.status === "stall") { await this.device.clearHalt("in", this.inEp); continue; }
      if (r.status !== "ok") throw new UsbError("io", "read: " + r.status);
      const got = new Uint8Array(r.data.buffer, r.data.byteOffset, r.data.byteLength);
      const all = new Uint8Array(this.pending.length + got.length);
      all.set(this.pending); all.set(got, this.pending.length);
      this.pending = all;
    }
    const out = this.pending.slice(0, n);
    this.pending = this.pending.slice(n);
    return out;
  }

  async close() {
    try { await this.device.releaseInterface(this.a.intf.interfaceNumber); } catch (_) {}
    try { await this.device.close(); } catch (_) {}
  }
}
