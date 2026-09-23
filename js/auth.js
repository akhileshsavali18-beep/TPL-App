// --- 1. Toast Notification Helper ---
function showToast(msg) {
  const toast = document.getElementById('toast');
  if (toast) {
    toast.innerText = msg;
    toast.classList.remove('hidden');
    setTimeout(() => toast.classList.add('hidden'), 3000);
  }
}

// --- 2. Production Firebase Configuration ---
const firebaseConfig = {
  apiKey: "AIzaSyDNUAx_Zhn-8RYKKkv5qAjMWwFWwI5tMI8",
  authDomain: "tpl-5bd9d.firebaseapp.com",
  projectId: "tpl-5bd9d",
  storageBucket: "tpl-5bd9d.firebasestorage.app",
  messagingSenderId: "940679131159",
  appId: "1:940679131159:android:f5ed5fc5b6f6ac285a2c52"
};

if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}
const auth = firebase.auth();
const db = firebase.firestore();

// --- 3. Auth State Handler ---
auth.onAuthStateChanged(user => {
  if (user) {
    document.getElementById('loginScreen').classList.add('hidden');
    document.getElementById('dashboardScreen').classList.remove('hidden');
    if (typeof fetchAllData === 'function') {
      fetchAllData();
    }
  } else {
    document.getElementById('dashboardScreen').classList.add('hidden');
    document.getElementById('loginScreen').classList.remove('hidden');
  }
});

// --- 4. Direct Login Function ---
async function handleLogin() {
  const errBox = document.getElementById('loginError');
  if (errBox) errBox.classList.add('hidden');

  const email = document.getElementById('adminEmail').value.trim();
  const pass = document.getElementById('adminPassword').value.trim();
  const btn = document.getElementById('loginBtn');

  if (!email || !pass) {
    if (errBox) {
      errBox.innerText = '⚠️ Please enter both Admin Email & Password!';
      errBox.classList.remove('hidden');
    }
    return;
  }

  btn.innerText = 'Verifying...';
  btn.disabled = true;

  try {
    await auth.signInWithEmailAndPassword(email, pass);
    btn.innerText = '✅ Success!';
  } catch (e) {
    btn.disabled = false;
    btn.innerText = 'Unlock Console';
    if (errBox) {
      errBox.innerText = 'Login Failed: ' + e.message;
      errBox.classList.remove('hidden');
    }
  }
}

// --- 5. Logout Function ---
function handleLogout() {
  if (confirm('Logout from Admin Console?')) {
    auth.signOut().then(() => showToast('Logged out!'));
  }
}

// --- 6. Bottom Navigation Tab Switcher ---
function switchTab(tab) {
  ['dashboard', 'payouts', 'users', 'tasks', 'settings'].forEach(t => {
    const content = document.getElementById('tabContent-' + t);
    const nav = document.getElementById('nav-' + t);
    if (content && nav) {
      if (t === tab) {
        content.classList.remove('hidden');
        nav.classList.add('active-nav');
        nav.classList.remove('text-gray-400');
      } else {
        content.classList.add('hidden');
        nav.classList.remove('active-nav');
        nav.classList.add('text-gray-400');
      }
    }
  });
}

