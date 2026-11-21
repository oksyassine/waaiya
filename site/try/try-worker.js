/* Waaiya's real voice filter in the visitor's browser: the app's model (DeepFilterNet3 streaming, int8) run hop by
   hop with ONNX Runtime Web, exactly as the app's engine runs it (480 samples at 48 kHz, state carried between hops,
   1440 samples of delay taken out). Fail-closed: any error returns an error, never the input. */
self.onmessage = async function (e) {
  var base = e.data.base, x = e.data.pcm;
  try {
    importScripts(base + "ort.wasm.min.js");
    ort.env.wasm.numThreads = 1;
    // the .gz copy is served with Content-Encoding: gzip (site/htaccess): ~3 MB instead of ~11 MB
    ort.env.wasm.wasmPaths = { wasm: base + "ort-wasm-simd-threaded.wasm.gz", mjs: base + "ort-wasm-simd-threaded.mjs" };
    var session = await ort.InferenceSession.create(base + "dfn3_stream_int8.onnx", { executionProviders: ["wasm"] });
    var r0 = await fetch(base + "dfn3_stream_int8.state_init.bin");
    if (!r0.ok) throw new Error("state " + r0.status);
    var state = new Float32Array(await r0.arrayBuffer());
    self.postMessage({ loaded: true });
    var H = 480, LAT = 1440, N = x.length, hops = Math.ceil((N + LAT) / H);
    var y = new Float32Array(hops * H), inb = new Float32Array(H);
    for (var h = 0; h < hops; h++) {
      inb.fill(0);
      if (h * H < N) inb.set(x.subarray(h * H, Math.min(N, h * H + H)));
      var r = await session.run({
        audio_in: new ort.Tensor("float32", inb, [H]),
        state_in: new ort.Tensor("float32", state, [state.length])
      });
      y.set(r.audio_out.data, h * H);
      state = r.state_out.data;
      if (h % 50 === 0) self.postMessage({ p: h / hops });
    }
    var out = y.slice(LAT, LAT + N);
    for (var i = 0; i < out.length; i++) if (!isFinite(out[i])) throw new Error("not finite");
    self.postMessage({ out: out }, [out.buffer]);
  } catch (err) {
    self.postMessage({ error: String((err && err.message) || err) });
  }
};
