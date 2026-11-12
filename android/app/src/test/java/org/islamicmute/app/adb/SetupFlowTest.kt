package org.islamicmute.app.adb

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PairingInputTest {
    @Test fun codes() {
        assertEquals(PairingInput.Parsed("482913", null), PairingInput.parse("482913"))
        assertEquals(PairingInput.Parsed("482913", null), PairingInput.parse(" 482 913 "))
        assertEquals(PairingInput.Parsed("482913", null), PairingInput.parse("٤٨٢٩١٣"))
        assertEquals(PairingInput.Parsed("482913", null), PairingInput.parse("۴۸۲۹۱۳"))
        assertNull(PairingInput.parse("48291"))
        assertNull(PairingInput.parse(""))
        assertNull(PairingInput.parse("192.168.1.5:37123"))
    }

    @Test fun codeWithPort() {
        assertEquals(PairingInput.Parsed("482913", 37123), PairingInput.parse("482913 37123"))
        assertEquals(PairingInput.Parsed("482913", 37123), PairingInput.parse("482913 192.168.1.5:37123"))
        assertEquals(PairingInput.Parsed("482913", 37123), PairingInput.parse("٤٨٢٩١٣ ١٩٢.١٦٨.١.٥:٣٧١٢٣"))
        assertEquals(PairingInput.Parsed("482913", null), PairingInput.parse("482913 99"))
    }
}

class AdbServicesTest {
    @Test fun onlyThisPhonesAnnouncement() {
        val local = setOf("192.168.1.5", "fe80::1%wlan0")
        fun f(host: String?) = AdbServices.Found("adb-X-y", host, 40000)
        assertTrue(AdbServices.isOurs(f("192.168.1.5"), local, 0))
        assertTrue(AdbServices.isOurs(f("FE80::1"), local, 0))
        assertTrue(AdbServices.isOurs(f("127.0.0.1"), local, 0))
        assertFalse(AdbServices.isOurs(f("192.168.1.9"), local, 0))
        assertTrue(AdbServices.isOurs(f(null), local, 0))
        assertFalse(AdbServices.isOurs(f(null), local, 1))
    }
}

class SetupFlowTest {
    @Test fun firstTimeCodeThenPort() {
        val f = SetupFlow(pairedBefore = false)
        assertEquals(SetupFlow.Note.OPEN_PAIRING_DIALOG, f.note)
        assertNull(f.connectPortFound(5555))          // not paired: do not try
        assertNull(f.codeEntered("123456", null))      // no pairing port yet: keep the code
        assertEquals(SetupFlow.Note.CODE_WAITING_FOR_DIALOG, f.note)
        assertEquals(SetupFlow.Action.Pair(40001, "123456"), f.pairingPortFound(40001))
        assertEquals(SetupFlow.Phase.PAIRING, f.phase)
        assertEquals(SetupFlow.Action.Connect(5555), f.pairSucceeded())
        assertEquals(SetupFlow.Phase.CONNECTING, f.phase)
        f.grantsDone(verified = true)
        assertEquals(SetupFlow.Phase.DONE, f.phase)
        assertNull(f.pairingPortFound(40002))
        f.timedOut()
        assertEquals(SetupFlow.Phase.DONE, f.phase)
    }

    @Test fun aCodeTypedLongBeforeThePairingScreenIsDropped() {
        var now = 0L
        val f = SetupFlow(false) { now }
        f.codeEntered("123456", null)
        now += SetupFlow.PENDING_CODE_MS + 1
        assertNull(f.pairingPortFound(40001))  // a new pairing screen has a new code
        assertEquals(SetupFlow.Note.ENTER_CODE, f.note)
        assertEquals(SetupFlow.Phase.WAITING, f.phase)
    }

    @Test fun portThenCodeThenConnectPortLater() {
        val f = SetupFlow(false)
        assertNull(f.pairingPortFound(40001))
        assertEquals(SetupFlow.Note.ENTER_CODE, f.note)
        assertEquals(SetupFlow.Action.Pair(40001, "654321"), f.codeEntered("654321", null))
        assertNull(f.pairSucceeded())
        assertEquals(SetupFlow.Note.WAITING_FOR_CONNECT_PORT, f.note)
        assertEquals(SetupFlow.Action.Connect(5555), f.connectPortFound(5555))
    }

    @Test fun typedPortWins() {
        val f = SetupFlow(false)
        f.pairingPortFound(40001)
        assertEquals(SetupFlow.Action.Pair(40999, "111111"), f.codeEntered("111111", 40999))
    }

    @Test fun wrongCodeLetsTheUserTryAgain() {
        val f = SetupFlow(false)
        f.pairingPortFound(40001)
        f.codeEntered("000000", null)
        assertNull(f.codeEntered("111111", null))  // busy pairing: ignored
        f.pairFailed(wrongCode = true)
        assertEquals(SetupFlow.Phase.WAITING, f.phase)
        assertEquals(SetupFlow.Note.WRONG_CODE, f.note)
        assertEquals(SetupFlow.Action.Pair(40001, "111111"), f.codeEntered("111111", null))
    }

    @Test fun pairedBeforeConnectsWithoutACode() {
        val f = SetupFlow(pairedBefore = true)
        assertEquals(SetupFlow.Action.Connect(37000), f.connectPortFound(37000))
        f.connectRefused()                              // adbd forgot us
        assertEquals(SetupFlow.Note.NOT_PAIRED, f.note)
        assertFalse(f.paired)
        assertNull(f.connectPortFound(37001))           // needs pairing first
        f.pairingPortFound(40001)
        assertEquals(SetupFlow.Action.Pair(40001, "222222"), f.codeEntered("222222", null))
        assertEquals(SetupFlow.Action.Connect(37001), f.pairSucceeded())
    }

    @Test fun samePortIsNotRetriedButANewOneIs() {
        val f = SetupFlow(true)
        f.connectPortFound(37000)
        f.connectFailed()
        assertNull(f.connectPortFound(37000))
        assertEquals(SetupFlow.Action.Connect(37002), f.connectPortFound(37002))
    }

    @Test fun grantsNotVisibleIsAFailure() {
        val f = SetupFlow(true)
        f.connectPortFound(37000)
        f.grantsDone(verified = false)
        assertEquals(SetupFlow.Phase.FAILED, f.phase)
        assertEquals(SetupFlow.Note.GRANT_FAILED, f.note)
    }

    @Test fun timeout() {
        val f = SetupFlow(false)
        f.timedOut()
        assertEquals(SetupFlow.Phase.FAILED, f.phase)
        assertEquals(SetupFlow.Note.TIMEOUT, f.note)
    }
}
