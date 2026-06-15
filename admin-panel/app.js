// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyD17EbUBpIjpDwtxXDc6gqvc6vTEh-agqo",
  authDomain: "hearmeoutfyp-8e14d.firebaseapp.com",
  projectId: "hearmeoutfyp-8e14d",
  storageBucket: "hearmeoutfyp-8e14d.firebasestorage.app",
  messagingSenderId: "943010250252",
  appId: "1:943010250252:web:35a4ee1bdbdb4d5c087829"
};

firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.firestore();

// UI refs
const signInBtn = document.getElementById('sign-in-btn');
const signOutBtn = document.getElementById('sign-out-btn');
const addBtn = document.getElementById('add-user-open');
const modal = document.getElementById('modal');
const modalClose = document.getElementById('modal-close');
const userForm = document.getElementById('user-form');
const usersList = document.getElementById('users-list');
const totalUsersEl = document.getElementById('total-users');
const totalAdminsEl = document.getElementById('total-admins');
const searchInput = document.getElementById('search');
const sortSelect = document.getElementById('sort');
const prevBtn = document.getElementById('prev-page');
const nextBtn = document.getElementById('next-page');
const pageInfo = document.getElementById('page-info');

let pageSize = 25;
let pageStack = [];
let currentCursor = null;
let currentOrder = { field: 'createdAt', dir: 'desc' };
let currentFilter = '';
let unsubscribe = null;
let currentPage = 1;

// Charts
let rolesChart = null;
let growthChart = null;

// ---------- Auth ----------
signInBtn.onclick = async () => {
  const provider = new firebase.auth.GoogleAuthProvider();
  try { await auth.signInWithPopup(provider); } 
  catch(e){ alert(e.message); }
};
signOutBtn.onclick = () => auth.signOut();

auth.onAuthStateChanged(u => {
  if(u){
    signInBtn.classList.add('hidden');
    signOutBtn.classList.remove('hidden');
    addBtn.classList.remove('hidden'); // always show
    initLoad();
    initDashboard();
  } else {
    signInBtn.classList.remove('hidden');
    signOutBtn.classList.add('hidden');
    addBtn.classList.add('hidden');
    if(unsubscribe) unsubscribe();
    usersList.innerHTML = '';
    totalUsersEl.textContent = '—';
    totalAdminsEl.textContent = '—';
  }
});

// ---------- UI handlers ----------
addBtn.onclick = () => openAdd();
modalClose.onclick = () => closeModal();

userForm.addEventListener('submit', async ev => {
  ev.preventDefault();
  const name = document.getElementById('name').value.trim();
  const email = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;
  const role = document.getElementById('role').value;

  if(!name || !email || !password) return alert('All fields required');

  try{
    const res = await fetch('http://localhost:5000/createUser', {
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ name, email, password, role })
    });
    const data = await res.json();
    if(data.error) throw new Error(data.error);
    await db.collection('users').doc(data.uid).set({
      name, email, role, createdAt: firebase.firestore.FieldValue.serverTimestamp(), disabled: false
    });
    closeModal();
  } catch(e){ alert(e.message); }
});

// ---------- Modal ----------
function openAdd(){
  document.getElementById('modal-title').textContent = 'Add user';
  document.getElementById('name').value = '';
  document.getElementById('email').value = '';
  document.getElementById('password').value = '';
  document.getElementById('role').value = 'user';
  modal.classList.remove('hidden');
}
function closeModal(){ modal.classList.add('hidden'); }

// ---------- Delete User ----------
document.addEventListener('click', async e => {
  if(e.target.matches('.delete-user')){
    const uid = e.target.dataset.uid;
    if(!uid) return;
    if(!confirm('Delete this user?')) return;
    try{
      const res = await fetch('http://localhost:5000/deleteUser',{
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ uid })
      });
      const data = await res.json();
      if(data.error) throw new Error(data.error);
      await db.collection('users').doc(uid).delete().catch(()=>{});
    } catch(err){ alert(err.message); }
  }
});

// ---------- Users List ----------
function buildQuery(limit=pageSize, startAfterTS=null){
  let q = db.collection('users').orderBy(currentOrder.field, currentOrder.dir).limit(limit);
  if(startAfterTS) q = q.startAfter(startAfterTS);
  return q;
}

function resetPaginationAndReload(){
  pageStack = [];
  currentCursor = null;
  currentPage = 1;
  subscribeToPage();
}

function initLoad(){ resetPaginationAndReload(); }

function subscribeToPage(){
  if(unsubscribe) unsubscribe();
  usersList.innerHTML = 'Loading...';
  const q = buildQuery(pageSize, currentCursor);
  unsubscribe = q.onSnapshot(snap => {
    const docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    const filtered = docs.filter(u => {
      if(!currentFilter) return true;
      return (u.name||'').toLowerCase().includes(currentFilter)
          || (u.email||'').toLowerCase().includes(currentFilter)
          || (u.role||'').toLowerCase().includes(currentFilter);
    });
    renderUsers(filtered);
    if(snap.docs.length>0){
      const lastDoc = snap.docs[snap.docs.length-1];
      currentCursor = lastDoc.get(currentOrder.field) || lastDoc.get('createdAt') || null;
      pageInfo.textContent = `Page ${currentPage}`;
    } else pageInfo.textContent = `Page ${currentPage} (no results)`;
    computeTotals();
  });
}

function loadNextPage(){ pageStack.push(currentCursor); currentPage++; subscribeToPage(); }
function loadPrevPage(){ if(pageStack.length===0){ currentCursor=null; currentPage=1; subscribeToPage(); return; } currentCursor=pageStack.pop(); currentPage--; subscribeToPage(); }

nextBtn.onclick = loadNextPage;
prevBtn.onclick = loadPrevPage;

let searchT;
searchInput.addEventListener('input', () => {
  clearTimeout(searchT);
  searchT = setTimeout(()=>{
    currentFilter = searchInput.value.trim().toLowerCase();
    resetPaginationAndReload();
  }, 250);
});

sortSelect.addEventListener('change', () => {
  const val = sortSelect.value;
  if(val.startsWith('createdAt')) currentOrder = { field:'createdAt', dir: val.endsWith('_asc')?'asc':'desc' };
  else if(val.startsWith('name')) currentOrder = { field:'name', dir: val.endsWith('_asc')?'asc':'desc' };
  else if(val.startsWith('role')) currentOrder = { field:'role', dir:'asc' };
  resetPaginationAndReload();
});

function renderUsers(users){
  usersList.innerHTML = '';
  totalUsersEl.textContent = users.length || '—';
  users.forEach(u => {
    const row = document.createElement('div');
    row.className = 'user-row';
    const createdAt = u.createdAt && u.createdAt.seconds ? new Date(u.createdAt.seconds*1000) : new Date();
    row.innerHTML = `
      <div>
        <h4>${escapeHtml(u.name||'—')}</h4>
        <div style="color:#9aa8c4">${escapeHtml(u.email||'—')}</div>
      </div>
      <div>${createdAt.toLocaleString()}</div>
      <div><span class="badge ${u.role}">${escapeHtml(u.role||'user')}</span></div>
      <div>${u.id||''}</div>
      <div class="user-actions">
        <button class="btn delete-user" data-uid="${u.id}">Delete</button>
      </div>
    `;
    usersList.appendChild(row);
  });
}

// ---------- Dashboard ----------
async function computeTotals(){
  const snap = await db.collection('users').get();
  const all = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  const total = all.length;
  const admins = all.filter(x => x.role==='admin'||x.role==='superadmin').length;
  totalUsersEl.textContent = total;
  totalAdminsEl.textContent = admins;

  const roles = {};
  all.forEach(u => roles[u.role||'user'] = (roles[u.role]||0)+1);

  const months = {};
  const now = new Date();
  for(let i=0;i<12;i++){
    const d = new Date(now.getFullYear(), now.getMonth()-i, 1);
    const key = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`;
    months[key]=0;
  }
  all.forEach(u=>{
    let ts = u.createdAt && u.createdAt.seconds ? new Date(u.createdAt.seconds*1000) : new Date();
    const key = `${ts.getFullYear()}-${String(ts.getMonth()+1).padStart(2,'0')}`;
    if(key in months) months[key]+=1;
  });

  const rolesLabels = Object.keys(roles);
  const rolesValues = rolesLabels.map(k=>roles[k]);
  if(!rolesChart){
    const ctx = document.getElementById('rolesChart').getContext('2d');
rolesChart = new Chart(ctx, {
  type: 'pie',
  data: { labels: rolesLabels, datasets:[{data:rolesValues}] },
  options: { responsive:true, maintainAspectRatio:false }
});

  } else {
    rolesChart.data.labels = rolesLabels;
    rolesChart.data.datasets[0].data = rolesValues;
    rolesChart.update();
  }

  const growthLabels = Object.keys(months).reverse();
  const growthValues = growthLabels.map(k=>months[k]);
  if(!growthChart){
    const ctx2 = document.getElementById('growthChart').getContext('2d');

growthChart = new Chart(ctx2, {
  type: 'line',
  data: { labels: growthLabels, datasets:[{label:'Signups', data:growthValues, fill:true}] },
  options: { responsive:true, maintainAspectRatio:false }
});  } else {
    growthChart.data.labels = growthLabels;
    growthChart.data.datasets[0].data = growthValues;
    growthChart.update();
  }
}

// ---------- Utils ----------
function escapeHtml(s){ return (s||'').toString().replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])) }
