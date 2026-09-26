const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const crypto = require("crypto");

initializeApp();
const db = getFirestore();

setGlobalOptions({
  region: "asia-south1",
  maxInstances: 10,
});

const APP_ID = "1:940679131159:android:edd514726cb0bf645a2c52";
const SOCIAL_MIN_SECONDS = 8;
const SOCIAL_SESSION_MINUTES = 10;
const WHEEL_REWARDS = [20, 2, 5, 0, 3, 1];

function requireAuth(request) {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Please sign in again.");
  }
  return request.auth.uid;
}

function cleanString(value, max = 200) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

function todayKey() {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

function newReferralCode() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = crypto.randomBytes(5);
  let out = "TPL";
  for (let i = 0; i < 5; i++) out += chars[bytes[i] % chars.length];
  return out;
}

function normalizeError(err) {
  if (err instanceof HttpsError) return err;
  logger.error(err);
  return new HttpsError("internal", "Secure reward service failed. Please try again.");
}

// App Check is intentionally enforced on every reward callable.
// This means the production APK must be registered in Firebase App Check.
const callableOptions = {
  enforceAppCheck: true,
};

exports.initializeUser = onCall(callableOptions, async (request) => {
  try {
    const uid = requireAuth(request);
    const username = cleanString(request.data?.username, 20);
    const email = cleanString(request.data?.email, 200).toLowerCase();
    const referralCode = cleanString(request.data?.referralCode, 20).toUpperCase();

    if (!/^[a-zA-Z0-9_]{3,20}$/.test(username)) {
      throw new HttpsError("invalid-argument", "Invalid username.");
    }
    if (!email.includes("@")) {
      throw new HttpsError("invalid-argument", "Invalid email.");
    }

    const userRef = db.collection("users").doc(uid);
    const existing = await userRef.get();
    if (existing.exists) return { ok: true, existing: true };

    const usernameSnap = await db.collection("users")
      .where("usernameLower", "==", username.toLowerCase())
      .limit(1)
      .get();
    if (!usernameSnap.empty && usernameSnap.docs[0].id !== uid) {
      throw new HttpsError("already-exists", "Username already taken.");
    }

    let referrerDoc = null;
    if (referralCode) {
      const refSnap = await db.collection("users")
        .where("referralCode", "==", referralCode)
        .limit(1)
        .get();
      if (!refSnap.empty && refSnap.docs[0].id !== uid) {
        referrerDoc = refSnap.docs[0];
      }
    }

    let myReferralCode = "";
    for (let i = 0; i < 5; i++) {
      const candidate = newReferralCode();
      const check = await db.collection("users")
        .where("referralCode", "==", candidate)
        .limit(1)
        .get();
      if (check.empty) {
        myReferralCode = candidate;
        break;
      }
    }
    if (!myReferralCode) {
      throw new HttpsError("aborted", "Could not create a unique referral code.");
    }

    const userData = {
      uid,
      email,
      displayName: username,
      name: username,
      coins: 0,
      taskCash: 0.0,
      referCash: 0.0,
      referCashLocked: 0.0,
      spinsLeft: 0,
      scratchLeft: 0,
      dailyBonusDate: null,
      dailyTaskProgress: 0,
      referralCode: myReferralCode,
      username,
      usernameLower: username.toLowerCase(),
      referredBy: referrerDoc ? referralCode : null,
      referredByUid: referrerDoc ? referrerDoc.id : null,
      referralBonusLockedCash: referrerDoc ? 5.0 : 0.0,
      referralBonusUnlocked: !referrerDoc,
      referralTaskCount: 0,
      withdrawalCount: 0,
      cashWithdrawalCount: 0,
      streakClaimedToday: false,
      hasConvertedToday: false,
      hasTaskWithdrawnToday: false,
      hasReferWithdrawnToday: false,
      createdAt: FieldValue.serverTimestamp(),
    };

    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(userRef);
      if (fresh.exists) return;

      if (referrerDoc) {
        const referrerRef = db.collection("users").doc(referrerDoc.id);
        const referrer = await tx.get(referrerRef);
        if (referrer.exists) {
          tx.update(referrerRef, {
            referCashLocked: FieldValue.increment(5.0),
          });
        }
      }

      tx.set(userRef, userData);
      if (referrerDoc) {
        const logRef = db.collection("referral_logs").doc(uid);
        tx.set(logRef, {
          referrerUid: referrerDoc.id,
          referredUid: uid,
          referredEmail: email,
          bonusGiven: 5.0,
          status: "locked",
          requiredTaskCount: 2,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
    });

    return { ok: true, referralCode: myReferralCode };
  } catch (err) {
    throw normalizeError(err);
  }
});

exports.resolveReferralCode = onCall(callableOptions, async (request) => {
  try {
    const code = cleanString(request.data?.code, 20).toUpperCase();
    if (!code) return { valid: false };
    const snap = await db.collection("users")
      .where("referralCode", "==", code)
      .limit(1)
      .get();
    return { valid: !snap.empty };
  } catch (err) {
    throw normalizeError(err);
  }
});

exports.resolveUsername = onCall(
  { ...callableOptions, enforceAppCheck: true },
  async (request) => {
    try {
      const username = cleanString(request.data?.username, 20).toLowerCase();
      if (!/^[a-zA-Z0-9_]{3,20}$/.test(username)) {
        throw new HttpsError("invalid-argument", "Invalid username.");
      }
      const snap = await db.collection("users")
        .where("usernameLower", "==", username)
        .limit(1)
        .get();
      if (snap.empty) {
        throw new HttpsError("not-found", "No account found with that username.");
      }
      return { email: snap.docs[0].data().email || "" };
    } catch (err) {
      throw normalizeError(err);
    }
  }
);

exports.startSocialTask = onCall(callableOptions, async (request) => {
  try {
    const uid = requireAuth(request);
    const taskId = cleanString(request.data?.taskId, 200);
    if (!taskId || taskId.includes("/")) {
      throw new HttpsError("invalid-argument", "Invalid task.");
    }

    const taskRef = db.collection("tasks").doc(taskId);
    const task = await taskRef.get();
    if (!task.exists || task.data()?.isActive === false) {
      throw new HttpsError("not-found", "Task is not available.");
    }

    const reward = Number(task.data()?.coins ?? 0);
    if (!Number.isInteger(reward) || reward < 0 || reward > 10000) {
      throw new HttpsError("failed-precondition", "Task reward is invalid.");
    }

    const sessionRef = db.collection("users").doc(uid)
      .collection("task_sessions").doc(taskId);

    await sessionRef.set({
      taskId,
      reward,
      startedAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + SOCIAL_SESSION_MINUTES * 60 * 1000),
      status: "started",
    }, { merge: true });

    return { ok: true, reward };
  } catch (err) {
    throw normalizeError(err);
  }
});

exports.completeSocialTask = onCall(callableOptions, async (request) => {
  try {
    const uid = requireAuth(request);
    const taskId = cleanString(request.data?.taskId, 200);
    if (!taskId || taskId.includes("/")) {
      throw new HttpsError("invalid-argument", "Invalid task.");
    }

    const taskRef = db.collection("tasks").doc(taskId);
    const userRef = db.collection("users").doc(uid);
    const sessionRef = userRef.collection("task_sessions").doc(taskId);
    const claimRef = userRef.collection("task_claims").doc(taskId);

    const result = await db.runTransaction(async (tx) => {
      const taskSnap = await tx.get(taskRef);
      const userSnap = await tx.get(userRef);
      const sessionSnap = await tx.get(sessionRef);
      const claimSnap = await tx.get(claimRef);

      if (!taskSnap.exists || taskSnap.data()?.isActive === false) {
        throw new HttpsError("not-found", "Task is not available.");
      }
      if (!userSnap.exists) {
        throw new HttpsError("failed-precondition", "Account setup is incomplete.");
      }
      if (claimSnap.exists) {
        return { already: true, reward: Number(claimSnap.data()?.reward ?? 0) };
      }
      if (!sessionSnap.exists) {
        throw new HttpsError("failed-precondition", "Start the task from the app first.");
      }

      const session = sessionSnap.data() || {};
      const startedAt = session.startedAt?.toMillis?.() ?? 0;
      const expiresAt = session.expiresAt?.toMillis?.() ?? 0;
      const now = Date.now();

      if (!startedAt || now - startedAt < SOCIAL_MIN_SECONDS * 1000) {
        throw new HttpsError("failed-precondition", "Please complete the task steps before claiming.");
      }
      if (expiresAt && now > expiresAt) {
        throw new HttpsError("deadline-exceeded", "Task session expired. Start the task again.");
      }

      const reward = Number(taskSnap.data()?.coins ?? 0);
      const user = userSnap.data() || {};
      const today = todayKey();
      const dailyProgress = user.dailyBonusDate === today
        ? Number(user.dailyTaskProgress ?? 0)
        : 0;
      const referralTaskCount = Number(user.referralTaskCount ?? 0);
      const referredByUid = user.referredByUid;
      const newReferralCount = referralTaskCount + 1;
      const referralLogRef = referredByUid
        ? db.collection("referral_logs").doc(uid)
        : null;
      const referralLogSnap = referralLogRef
        ? await tx.get(referralLogRef)
        : null;
      const referrerRef = (referredByUid && newReferralCount >= 2 && user.referralBonusUnlocked !== true)
        ? db.collection("users").doc(referredByUid)
        : null;
      const referrerSnap = referrerRef
        ? await tx.get(referrerRef)
        : null;

      tx.update(userRef, {
        coins: FieldValue.increment(reward),
        dailyBonusDate: today,
        dailyTaskProgress: dailyProgress + 1,
        referralTaskCount: newReferralCount,
        lastRewardAt: FieldValue.serverTimestamp(),
      });

      tx.set(claimRef, {
        taskId,
        reward,
        title: cleanString(taskSnap.data()?.title, 200),
        createdAt: FieldValue.serverTimestamp(),
        source: "social_task",
      });

      tx.set(db.collection("transactions").doc(), {
        uid,
        category: "reward",
        title: cleanString(taskSnap.data()?.title, 200) || "Task Reward",
        coins: reward,
        amount: 0,
        status: "success",
        source: "social_task",
        taskId,
        createdAt: FieldValue.serverTimestamp(),
      });

      if (referredByUid && referralLogRef && referralLogSnap) {
        const currentProgress = Number(referralLogSnap.data()?.progress ?? referralTaskCount);
        const progress = Math.max(currentProgress, newReferralCount);
        tx.update(referralLogRef, {
          progress,
          updatedAt: FieldValue.serverTimestamp(),
        });

        if (newReferralCount >= 2 && user.referralBonusUnlocked !== true && referrerRef && referrerSnap?.exists) {
            tx.update(referrerRef, {
              referCash: FieldValue.increment(5.0),
              referCashLocked: FieldValue.increment(-5.0),
            });
            tx.update(userRef, {
              referralBonusUnlocked: true,
            });
            tx.update(referralLogRef, {
              status: "unlocked",
              unlockedAt: FieldValue.serverTimestamp(),
            });
          }
        }
      }

      return { already: false, reward };
    });

    return { ok: true, ...result };
  } catch (err) {
    throw normalizeError(err);
  }
});

exports.claimSpin = onCall(
  { ...callableOptions, consumeAppCheckToken: true },
  async (request) => {
    try {
      const uid = requireAuth(request);
      const userRef = db.collection("users").doc(uid);
      const result = await db.runTransaction(async (tx) => {
        const userSnap = await tx.get(userRef);
        if (!userSnap.exists) throw new HttpsError("failed-precondition", "Account setup is incomplete.");
        const user = userSnap.data() || {};
        const today = todayKey();

        const qualified = Number(user.cpaleadQualifiedTasks ?? 0);
        if (qualified < 1) {
          throw new HttpsError("failed-precondition", "Complete at least 1 qualified offer first.");
        }

        let spins = Number(user.spinsLeft ?? 0);
        if (user.dailyBonusDate !== today) spins = 1;
        if (spins <= 0) {
          throw new HttpsError("resource-exhausted", "No spins left today.");
        }

        const index = crypto.randomInt(0, WHEEL_REWARDS.length);
        const reward = WHEEL_REWARDS[index];
        tx.update(userRef, {
          dailyBonusDate: today,
          spinsLeft: spins - 1,
          lastSpinAt: FieldValue.serverTimestamp(),
          ...(reward >= 20 ? { coins: FieldValue.increment(reward) } : {}),
        });

        if (reward >= 20) {
          tx.set(db.collection("transactions").doc(), {
            uid,
            category: "reward",
            title: "Spin Bonus",
            coins: reward,
            amount: 0,
            status: "success",
            source: "spin",
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        return { reward, index, spinsLeft: spins - 1 };
      });
      return { ok: true, ...result };
    } catch (err) {
      throw normalizeError(err);
    }
  }
);

exports.claimScratch = onCall(
  { ...callableOptions, consumeAppCheckToken: true },
  async (request) => {
    try {
      const uid = requireAuth(request);
      const userRef = db.collection("users").doc(uid);
      const result = await db.runTransaction(async (tx) => {
        const userSnap = await tx.get(userRef);
        if (!userSnap.exists) throw new HttpsError("failed-precondition", "Account setup is incomplete.");
        const user = userSnap.data() || {};
        if (Number(user.cpaleadQualifiedTasks ?? 0) < 3) {
          throw new HttpsError("failed-precondition", "Complete at least 3 qualified offers first.");
        }

        let scratches = Number(user.scratchLeft ?? 0);
        if (user.dailyBonusDate !== todayKey()) scratches = 1;
        if (scratches <= 0) {
          throw new HttpsError("resource-exhausted", "No scratches left today.");
        }

        tx.update(userRef, {
          dailyBonusDate: todayKey(),
          scratchLeft: scratches - 1,
          lastScratchAt: FieldValue.serverTimestamp(),
        });
        return { scratchesLeft: scratches - 1 };
      });
      return { ok: true, ...result };
    } catch (err) {
      throw normalizeError(err);
    }
  }
);

exports.convertCoins = onCall(callableOptions, async (request) => {
  try {
    const uid = requireAuth(request);
    const coins = Number(request.data?.coins);
    if (!Number.isInteger(coins) || coins < 100 || coins > 1000000) {
      throw new HttpsError("invalid-argument", "Enter a valid coin amount.");
    }

    const userRef = db.collection("users").doc(uid);
    const settingsSnap = await db.collection("settings").doc("economy").get();
    const rate = Math.max(1, Number(settingsSnap.data()?.coinRate ?? 100));

    const result = await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw new HttpsError("failed-precondition", "Account setup is incomplete.");
      const data = userSnap.data() || {};
      const balance = Number(data.coins ?? 0);
      if (balance < coins) throw new HttpsError("failed-precondition", "Insufficient coins.");

      const cash = coins / rate;
      tx.update(userRef, {
        coins: balance - coins,
        taskCash: FieldValue.increment(cash),
        hasConvertedToday: true,
      });
      tx.set(db.collection("transactions").doc(), {
        uid,
        category: "coin",
        title: "Coins to Cash",
        coins,
        amount: cash,
        status: "success",
        source: "conversion",
        createdAt: FieldValue.serverTimestamp(),
      });
      return { coins, cash, rate };
    });

    return { ok: true, ...result };
  } catch (err) {
    throw normalizeError(err);
  }
});

exports.requestWithdrawal = onCall(callableOptions, async (request) => {
  try {
    const uid = requireAuth(request);
    const isCash = request.data?.isCash === true;
    const amount = Number(request.data?.amount);
    const upi = cleanString(request.data?.upi, 120);

    if (!Number.isFinite(amount) || amount <= 0 || amount > 100000) {
      throw new HttpsError("invalid-argument", "Invalid withdrawal amount.");
    }
    if (!/^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$/.test(upi)) {
      throw new HttpsError("invalid-argument", "Invalid UPI ID.");
    }

    const economy = (await db.collection("settings").doc("economy").get()).data() || {};
    const minimum = isCash
      ? Number(economy.minTask ?? 25)
      : Number(economy.minRefer ?? 50);

    if (amount < minimum) {
      throw new HttpsError("failed-precondition", `Minimum withdrawal is ₹${minimum}.`);
    }

    const userRef = db.collection("users").doc(uid);
    const withdrawalRef = db.collection("withdrawals").doc();

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw new HttpsError("failed-precondition", "Account setup is incomplete.");
      const data = userSnap.data() || {};
      const field = isCash ? "taskCash" : "referCash";
      const balance = Number(data[field] ?? 0);

      if (balance < amount) {
        throw new HttpsError("failed-precondition", "Insufficient balance.");
      }

      const updates = {
        [field]: balance - amount,
        upiId: upi,
        withdrawalCount: FieldValue.increment(1),
        ...(isCash ? { cashWithdrawalCount: FieldValue.increment(1), hasTaskWithdrawnToday: true } : { hasReferWithdrawnToday: true }),
      };

      tx.update(userRef, updates);
      tx.set(withdrawalRef, {
        uid,
        userName: data.displayName || "TPL Player",
        userEmail: data.email || "",
        upiId: upi,
        amount,
        type: isCash ? "Cash Balance" : "Referral Balance",
        status: "pending",
        mode: "manual",
        requestId: withdrawalRef.id,
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    return { ok: true, requestId: withdrawalRef.id };
  } catch (err) {
    throw normalizeError(err);
  }
});

// CPAlead webhook: configure CPAlead to call this endpoint after a verified conversion.
// It is intentionally idempotent and never trusts the mobile client for reward crediting.
// Expected parameters: uid/subid, lead_id/transaction_id, payout/amount, optional secret.
exports.cpaleadPostback = onRequest(async (req, res) => {
  try {
    if (req.method !== "GET" && req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const body = req.method === "POST" ? (req.body || {}) : req.query;
    const uid = cleanString(body.uid || body.subid || body.sub_id, 128);
    const leadId = cleanString(body.lead_id || body.leadid || body.transaction_id || body.txid, 200);
    const payout = Number(body.payout ?? body.amount ?? 0);

    if (!uid || !leadId || !Number.isFinite(payout) || payout <= 0) {
      return res.status(400).send("invalid");
    }

    // Optional secret. Store it in environment/secret configuration before enabling
    // the webhook in production. If CPAlead sends a secret parameter, validate it here.
    const configuredSecret = process.env.CPALEAD_POSTBACK_SECRET || "";
    const suppliedSecret = cleanString(body.secret || body.token || "", 200);
    if (configuredSecret && suppliedSecret !== configuredSecret) {
      return res.status(403).send("forbidden");
    }

    const processedRef = db.collection("processed_leads").doc(leadId);
    const userRef = db.collection("users").doc(uid);
    const offerwall = (await db.collection("settings").doc("offerwalls").get()).data() || {};
    const coinsPerPayoutUnit = Math.max(1, Number(offerwall.coinsPerPayoutUnit ?? 100));

    await db.runTransaction(async (tx) => {
      const processed = await tx.get(processedRef);
      if (processed.exists) return;

      const user = await tx.get(userRef);
      if (!user.exists) throw new Error("user-not-found");
      const coins = Math.max(0, Math.round(payout * coinsPerPayoutUnit));

      tx.update(userRef, {
        coins: FieldValue.increment(coins),
        cpaleadQualifiedTasks: FieldValue.increment(1),
        lastOfferRewardAt: FieldValue.serverTimestamp(),
      });

      tx.set(processedRef, {
        leadId,
        uid,
        payout,
        coins,
        processedAt: FieldValue.serverTimestamp(),
      });

      tx.set(db.collection("transactions").doc(), {
        uid,
        category: "offer",
        title: "CPAlead Offer Reward",
        coins,
        amount: 0,
        payout,
        status: "success",
        source: "cpalead_postback",
        leadId,
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    return res.status(200).send("ok");
  } catch (err) {
    logger.error("CPAlead postback failed", err);
    return res.status(500).send("error");
  }
});
