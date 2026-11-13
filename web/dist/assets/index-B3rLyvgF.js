(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const i of document.querySelectorAll('link[rel="modulepreload"]'))s(i);new MutationObserver(i=>{for(const l of i)if(l.type==="childList")for(const a of l.addedNodes)a.tagName==="LINK"&&a.rel==="modulepreload"&&s(a)}).observe(document,{childList:!0,subtree:!0});function n(i){const l={};return i.integrity&&(l.integrity=i.integrity),i.referrerPolicy&&(l.referrerPolicy=i.referrerPolicy),i.crossOrigin==="use-credentials"?l.credentials="include":i.crossOrigin==="anonymous"?l.credentials="omit":l.credentials="same-origin",l}function s(i){if(i.ep)return;i.ep=!0;const l=n(i);fetch(i.href,l)}})();const Re={check:'<path d="M20 6 9 17l-5-5"/>',x:'<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',wrench:'<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',gauge:'<path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/>',palette:'<circle cx="13.5" cy="6.5" r=".5" fill="currentColor"/><circle cx="17.5" cy="10.5" r=".5" fill="currentColor"/><circle cx="8.5" cy="7.5" r=".5" fill="currentColor"/><circle cx="6.5" cy="12.5" r=".5" fill="currentColor"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/>',disc:'<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="2"/>',car:'<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/>',armchair:'<path d="M19 9V6a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v3"/><path d="M3 16a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5a2 2 0 0 0-4 0v1.5a.5.5 0 0 1-.5.5h-9a.5.5 0 0 1-.5-.5V11a2 2 0 0 0-4 0z"/><path d="M5 18v2"/><path d="M19 18v2"/>',lightbulb:'<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"/><path d="M9 18h6"/><path d="M10 22h4"/>',window:'<rect x="2" y="4" width="20" height="16" rx="2"/><path d="M10 4v4"/><path d="M2 8h20"/><path d="M6 4v4"/>',plate:'<rect width="20" height="12" x="2" y="6" rx="2"/><path d="M6 12h.01"/><path d="M18 12h.01"/>',layers:'<path d="M12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>',plus:'<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M8 12h8"/><path d="M12 8v8"/>',horn:'<path d="M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z"/><path d="M16 9a5 5 0 0 1 0 6"/><path d="M19.364 18.364a9 9 0 0 0 0-12.728"/>',reset:'<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',loader:'<path d="M21 12a9 9 0 1 1-6.219-8.56"/>'},h=(e,t=16,n=2.2,s="")=>`<svg class="${s}" width="${t}" height="${t}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${n}" stroke-linecap="round" stroke-linejoin="round">${Re[e]??""}</svg>`,oe=()=>`<span class="brand-mark">${h("wrench",22,2)}</span>`;let xe={};function ze(e){xe=e}function o(e,...t){let n=0;return(xe[e]??e).replace(/%[sd]/g,()=>String(t[n++]??""))}const Be={"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"},f=e=>document.getElementById(e),r=e=>String(e??"").replace(/[&<>"']/g,t=>Be[t]),x=e=>"$"+Math.round(e).toLocaleString("en-US"),S=e=>e===void 0?e:JSON.parse(JSON.stringify(e)),re=(e,t)=>JSON.stringify(e)===JSON.stringify(t),p=e=>Array.isArray(e)?e:e?Object.values(e):[],ce=e=>[1,3,5].map(t=>parseInt(e.slice(t,t+2),16)),We=e=>"#"+e.map(t=>t.toString(16).padStart(2,"0")).join(""),Ue=e=>new Promise(t=>setTimeout(t,e)),G=f("inspect");function Je(e){const t=Math.min(e.engine,e.body);return t>=75?{tone:"is-ok",label:o("ui_condition_good")}:t>=40?{tone:"is-warn",label:o("ui_condition_work")}:{tone:"is-bad",label:o("ui_condition_bad")}}function be(e,t,n,s){const i=Array.from({length:n},(a,c)=>`<span class="pip ${c<t?"is-on":""}"></span>`).join(""),l=n===0||t===0;return`
    <div class="board-row ${n>0&&t===n?"is-maxed":""}">
      <span class="board-name">${r(e)}</span>
      <span class="pips">${i}</span>
      <span class="board-stat ${l?"is-none":""}">${r(n===0?o("ui_na"):s)}</span>
    </div>`}function Xe(e){if(!e){G.innerHTML="";return}const t=Je(e),n=p(e.upgrades).map(l=>be(l.label,l.level,l.max,l.name));n.push(be(o("group_turbo"),e.turbo?1:0,1,o(e.turbo?"desc_installed":"option_none")));const s=`
    <div class="hud-head">
      <span class="mode-mark">${h("wrench",13)}</span>
      <div class="grow">
        <div class="hud-title">${r(e.name)}</div>
        <div class="hud-sub">${r(e.plate)} · ${r(o("ui_inspection"))}</div>
      </div>
    </div>
    <div class="status ${t.tone}">
      <span class="status-dot"></span>
      <div>
        <strong>${r(t.label)}</strong>
        <small>${r(o("ui_engine"))} ${e.engine}% · ${r(o("ui_body"))} ${e.body}%</small>
      </div>
    </div>
    <div class="hud-cap">${r(o("ui_installed_upgrades"))}</div>
    <div class="board">${n.join("")}</div>`;let i=G.firstElementChild;i||(i=document.createElement("div"),i.className="hud-card",G.appendChild(i)),i.innerHTML=s}const Ge=window.GetParentResourceName?window.GetParentResourceName():"whey_mechanic";async function m(e,t={}){return await(await fetch(`https://${Ge}/${e}`,{method:"POST",headers:{"Content-Type":"application/json; charset=UTF-8"},body:JSON.stringify(t)})).json()}async function ue(e,t={}){try{return await m(e,t)||{ok:!1,msg:o("no_reply")}}catch(n){return console.error(n),{ok:!1,msg:o("ui_unreachable")}}}const we=["ui_step_nuts","ui_step_harness","ui_step_fluids"],Ye=650,Me=[0,2,4,1,3],I=[{id:"red",hex:"#ff4d5e"},{id:"yellow",hex:"#ffd23f"},{id:"blue",hex:"#3d8bff"},{id:"green",hex:"#35d07f"}],Ve=.3,O=[.72,.86],j=f("install");let w=null,P=0;const B=()=>f("stage");function ge(e){const t=[...e];for(let n=t.length-1;n>0;n--){const s=Math.floor(Math.random()*(n+1));[t[n],t[s]]=[t[s],t[n]]}return t}function Qe(e,t,n){return Array.from({length:6},(s,i)=>{const l=Math.PI/3*i;return`${(e+n*Math.cos(l)).toFixed(1)},${(t+n*Math.sin(l)).toFixed(1)}`}).join(" ")}function de(e){f("installHint").textContent=e}function W(e){e.endsAt-=e.penalty*1e3;const t=f("installClock");t.classList.remove("is-hit"),t.offsetWidth,t.classList.add("is-hit")}function Te(e){f("installSteps").innerHTML=we.map((t,n)=>`<span class="step ${n<e.step?"is-done":n===e.step?"is-active":""}"><b>${n<e.step?h("check",12,3):n+1}</b>${r(o(t))}</span>`).join("")}function Se(){w=null,j.hidden=!0,j.innerHTML=""}function U(e,t){w&&(Se(),m("install:done",{ok:e,reason:t}))}function Le(e){return Me.find(t=>!e.done.has(t))}function Ee(e){const t=Le(e),n=[0,1,2,3,4].map(s=>{const i=(s*72-90)*Math.PI/180,l=130+Math.cos(i)*62,a=130+Math.sin(i)*62;return e.done.has(s)?`<circle cx="${l}" cy="${a}" r="9" class="nut-hole" />`:`
        <g class="nut ${s===t?"is-next":""}" data-nut="${s}" style="transform-origin:${l}px ${a}px">
          <circle cx="${l}" cy="${a}" r="21" class="nut-hit" />
          <polygon points="${Qe(l,a,13)}" class="nut-body" />
          <circle cx="${l}" cy="${a}" r="18" class="nut-ring" pathLength="100" />
        </g>`}).join("");B().innerHTML=`
    <svg class="wheel" viewBox="0 0 260 260">
      <circle cx="130" cy="130" r="124" class="tyre" />
      <circle cx="130" cy="130" r="98" class="rim" />
      <circle cx="130" cy="130" r="32" class="hub" />
      ${n}
    </svg>`}function Ce(e){const t={type:"nuts",done:new Set,holding:null};e.game=t,de(o("ui_hint_nuts")),Ee(t)}function Oe(e){return e.querySelector(".nut-ring")}function Ze(e,t,n){const s=n.closest("[data-nut]");if(!s)return;const i=Number(s.dataset.nut);if(i!==Le(t)){W(e),s.classList.add("is-wrong"),setTimeout(()=>s.classList.remove("is-wrong"),300);return}t.holding={i,el:s,start:performance.now()}}function et(e,t,n){const s=t.holding;if(!s)return;const i=Math.min(1,(n-s.start)/Ye),l=Oe(s.el);if(l&&(l.style.strokeDasharray=`${i*100} 100`),s.el.style.transform=`rotate(${-i*300}deg)`,!(i<1)){if(t.done.add(s.i),t.holding=null,t.done.size===Me.length){fe(e);return}Ee(t)}}function tt(e){const t=e.holding;if(!t)return;const n=Oe(t.el);n&&(n.style.strokeDasharray="0 100"),t.el.style.transform="",e.holding=null}function te(e){const t=a=>45+a*56,n=a=>{var c;return((c=I.find(u=>u.id===a))==null?void 0:c.hex)??""},s=[...e.linked].map(a=>{const c=t(e.left.findIndex(d=>d.id===a)),u=t(e.right.findIndex(d=>d.id===a));return`<path d="M76 ${c} C 210 ${c}, 230 ${u}, 364 ${u}" stroke="${n(a)}" class="wire" />`}).join(""),i=e.left.map((a,c)=>`
        <g class="plug ${e.linked.has(a.id)?"is-linked":e.picked===a.id?"is-picked":""}" data-left="${a.id}">
          <rect x="20" y="${t(c)-16}" width="56" height="32" rx="6" class="plug-body" />
          <rect x="28" y="${t(c)-6}" width="40" height="12" rx="3" fill="${a.hex}" />
        </g>`).join(""),l=e.right.map((a,c)=>`
        <g class="plug ${e.linked.has(a.id)?"is-linked":""}" data-right="${a.id}">
          <rect x="364" y="${t(c)-16}" width="56" height="32" rx="6" class="plug-body" />
          <circle cx="392" cy="${t(c)}" r="8" fill="${a.hex}" />
        </g>`).join("");B().innerHTML=`<svg class="harness" viewBox="0 0 440 250">${s}${i}${l}</svg>`}function nt(e){const t={type:"harness",left:ge(I),right:ge(I),picked:null,linked:new Set};e.game=t,de(o("ui_hint_harness")),te(t)}function st(e,t,n){var l,a;const s=(l=n.closest("[data-left]"))==null?void 0:l.dataset.left,i=(a=n.closest("[data-right]"))==null?void 0:a.dataset.right;if(s&&!t.linked.has(s)){t.picked=s,te(t);return}if(!(!i||!t.picked||t.linked.has(i))){if(i===t.picked){if(t.linked.add(t.picked),t.picked=null,t.linked.size===I.length){fe(e);return}}else W(e),t.picked=null;te(t)}}function K(e){const t=e.fluids.map((n,s)=>`
        <div class="gauge ${s<e.index?"is-done":s===e.index?"is-active":""}">
          <div class="gauge-tube">
            <div class="gauge-band" style="bottom:${O[0]*100}%;height:${(O[1]-O[0])*100}%"></div>
            <div class="gauge-fill" data-fill="${s}" style="height:${n.level*100}%;background:${n.hex}"></div>
          </div>
          <span>${s<e.index?h("check",12,3):""}${r(n.label)}</span>
        </div>`).join("");B().innerHTML=`
    <div class="fluids">
      <div class="gauges">${t}</div>
      <button class="btn btn--primary pour" data-pour>${r(o("ui_pour",e.fluids[e.index].label))}</button>
    </div>`}function it(e){const t={type:"fluids",index:0,pouring:!1,fluids:[{label:o("ui_engine_oil"),hex:"#d9a23a",level:.12+Math.random()*.15},{label:o("ui_coolant"),hex:"#35d0c4",level:.12+Math.random()*.15}]};e.game=t,de(o("ui_hint_fluids")),K(t)}function at(e,t){t.closest("[data-pour]")&&(e.pouring=!0)}function lt(e,t,n){if(!t.pouring)return;const s=t.fluids[t.index];if(s.level+=Ve*n,s.level>=1){t.pouring=!1,s.level=.4,W(e),K(t);return}const i=B().querySelector(`[data-fill="${t.index}"]`);i&&(i.style.height=`${s.level*100}%`)}function ot(e,t){if(!t.pouring)return;t.pouring=!1;const n=t.fluids[t.index];if(!(n.level<O[0])){if(n.level>O[1]){n.level=.5,W(e),K(t);return}if(t.index+=1,t.index>=t.fluids.length){fe(e);return}K(t)}}const rt=[Ce,nt,it];function fe(e){if(e.step+=1,e.step>=we.length){U(!0);return}Te(e),rt[e.step](e)}function je(e){const t=w;if(!t)return;const n=Math.max(0,t.endsAt-Date.now());if(f("installClock").style.width=`${n/(t.seconds*1e3)*100}%`,f("installTime").textContent=`${Math.ceil(n/1e3)}s`,n<=0){U(!1,"time");return}const s=P?(e-P)/1e3:0,i=t.game;P=e,(i==null?void 0:i.type)==="nuts"?et(t,i,e):(i==null?void 0:i.type)==="fluids"&&lt(t,i,s),w&&requestAnimationFrame(je)}function ct(e){const t=e.seconds||30,n={seconds:t,penalty:e.penalty||1.5,endsAt:Date.now()+t*1e3,step:0,game:null},s=p(e.parts),i=s.length===1?s[0]:o("ui_parts_n",s.length);w=n,j.innerHTML=`
    <section class="install-card">
      <header class="panel-head">
        ${oe()}
        <div class="panel-title">
          <h1>${r(o("ui_fitting"))}</h1>
          <p>${r(e.vehicle)} · ${r(String(e.plate??"").trim())} · ${r(i)}</p>
        </div>
        <span class="install-time" id="installTime"></span>
        <button class="key-btn" data-install="cancel">${r(o("ui_esc"))}</button>
      </header>
      <div class="install-clock"><span id="installClock"></span></div>
      <div class="steps" id="installSteps"></div>
      <div class="stage" id="stage"></div>
      <p class="hint install-hint" id="installHint"></p>
    </section>`,j.hidden=!1,Te(n),Ce(n),P=0,requestAnimationFrame(je)}function ut(){Se()}function dt(){return w?(U(!1,"cancel"),!0):!1}j.addEventListener("pointerdown",e=>{const t=w,n=e.target;if(!t)return;if(n.closest('[data-install="cancel"]')){U(!1,"cancel");return}const s=t.game;(s==null?void 0:s.type)==="nuts"?Ze(t,s,n):(s==null?void 0:s.type)==="harness"?st(t,s,n):(s==null?void 0:s.type)==="fluids"&&at(s,n)});window.addEventListener("pointerup",()=>{const e=w,t=e==null?void 0:e.game;!e||!t||(t.type==="nuts"?tt(t):t.type==="fluids"&&ot(e,t))});const ye=3200,Y=f("toasts");function J(e,t){var s;const n=document.createElement("div");for(n.className=`toast ${t?"":"toast--error"}`,n.innerHTML=`
    <span class="toast-icon">${h(t?"check":"x",15,3)}</span>
    <div class="toast-body">
      <div class="toast-title">${r(o(t?"ui_done":"ui_failed"))}</div>
      <div class="toast-text">${r(e)}</div>
    </div>
    <span class="toast-bar" style="animation-duration:${ye}ms"></span>`;Y.children.length>2;)(s=Y.firstChild)==null||s.remove();Y.appendChild(n),setTimeout(()=>{n.classList.add("is-leaving"),setTimeout(()=>n.remove(),200)},ye)}const ve=["#ffffff","#ff2f2f","#ff8b2c","#ffe834","#9cff2e","#2fff8b","#38b6ff","#2a6dff","#a447ff","#ff2fa4"],ft=/^#?([0-9a-f]{6})$/i,pt=["side_left","side_right","side_front","side_back"],y=f("shop"),L=f("drag"),ne=f("camHint");let b=null,E=null,se=null;const H=(e,t)=>e.meta.groups[t],ht=(e,t)=>Object.keys(e.meta.groups).filter(n=>e.meta.groups[n]===t),D=e=>e.extras??{},He=e=>"key"in e?e.key:e.type,V=e=>`data-value="${r(JSON.stringify(e))}"`;function pe(e,t){const n=e.current[t];return typeof n=="number"&&n>=0&&n<=5?n:0}function _(e,t){const n=e.meta.prices,s=n[t]??n.part;return typeof s=="number"?s:0}function Ne(e,t,n){const s=e.meta.prices.performance[t];return s?p(s)[Number(n)+1]||0:null}function mt(e){E||(E={},requestAnimationFrame(()=>{const t=E;E=null,m("customs:preview",t)})),Object.assign(E,S(e))}function $(e,t){e.meta.bike&&("modFrontWheels"in t&&(t.modBackWheels=t.modFrontWheels),"modCustomTiresF"in t&&(t.modCustomTiresR=t.modCustomTiresF)),Object.assign(e.current,t);const n={};for(const s of new Set(Object.keys(t).map(i=>H(e,i))))for(const i of ht(e,s))e.current[i]!==void 0&&(n[i]=e.current[i]);mt(n)}function X(e){const{original:t,current:n,meta:s}=e,i=Object.keys(s.groups).filter(d=>d!=="extras"&&n[d]!==void 0),l=new Set(i.filter(d=>!re(n[d],t[d])).map(d=>s.groups[d])),a={};for(const d of i)l.has(s.groups[d])&&(a[d]=n[d]);const c=D(t),u={};for(const[d,q]of Object.entries(D(n)))c[d]!==q&&(u[d]=q);return Object.keys(u).length&&(a.extras=u),a}function he(e,t){const n=new Set;let s=0;for(const[i,l]of Object.entries(t)){const a=H(e,i),c=Ne(e,i,l);c!==null?s+=c:a==="turbo"?s+=l?_(e,"turbo"):0:a==="extra"?s+=_(e,"extra")*Object.keys(l).length:n.has(a)||(n.add(a),s+=_(e,a))}return s}function $e(e,t,n){if(re(n,e.original[t]))return`<small class="is-installed">${r(o("desc_installed"))}</small>`;let s=Ne(e,t,n)??_(e,H(e,t));return t==="modTurbo"&&(s=n?_(e,"turbo"):0),`<small>${s>0?x(s):r(o("ui_free"))}</small>`}function bt(e){switch(e.type){case"paint":return[e.key,e.finishKey];case"wheels":return["wheels","modFrontWheels"];case"smoke":return["modSmokeEnabled","tyreSmokeColor"];case"xenon":return["modXenon","xenonColor"];case"neon":return["neonEnabled","neonColor"];case"extras":return["extras"];default:return[e.key]}}const me=(e,t)=>bt(e).some(n=>n in t);function ie(e,t){const n=e.current[t];if(Array.isArray(n))return n.slice(0,3);const s=typeof n=="number"?e.meta.colours.find(i=>i.id===n):void 0;return s!=null&&s.hex?ce(s.hex):[120,120,120]}function Ae(e){e!==se&&(se=e,m("customs:focus",{section:e}))}function v(e,t,n){return`
    <section class="card" data-focus="${r(He(e))}">
      <header class="card-head"><h2>${r(e.title)}</h2>${n}</header>
      <div class="card-body">${t}</div>
    </section>`}function F(e,t){return me(e,t)?`<span class="pill pill--warn">${r(o("ui_changed"))}</span>`:""}function C(e,t,n,s){return me(n,s)?F(n,s):`<span class="pill pill--muted">${x(_(e,t))}</span>`}function M(e,t,n,s,i){return`
    <button class="tile ${s?"is-active":""}" ${e}>
      <span class="tile-head">
        ${i?`<span class="dot" style="background:${i}"></span>`:""}
        <strong>${r(t)}</strong>
        ${s?`<span class="tile-check">${h("check",14,2.6)}</span>`:""}
      </span>
      ${n}
    </button>`}function Q(e,t,n,s){const i=s??e.meta.colours.map(u=>u.hex??""),l=We(ie(e,t)),a=n?`data-finish-key="${n}"`:"";return`
    <div class="swatches">${i.map(u=>`<button class="swatch ${u===l?"is-active":""}" style="background:${u}"
          data-rgb-preset="${t}" data-hex="${u}" ${a}></button>`).join("")}</div>
    <div class="rgb">
      <span class="rgb-preview" data-rgb-preview="${t}" style="background:${l}"></span>
      <label class="hex">
        <span class="field-label">${r(o("ui_hex"))}</span>
        <input class="hex-input" type="text" maxlength="7" spellcheck="false" autocomplete="off"
          value="${l.toUpperCase()}" data-hex-input="${t}" ${a} />
      </label>
    </div>`}function gt(e,t,n){var s;switch(t.type){case"list":{const i=e.current[t.key],l=p(t.options).map(a=>{const c=`data-set="${r(t.key)}" ${V(a.value)}`;return M(c,a.label,$e(e,t.key,a.value),re(i,a.value))}).join("");return v(t,`<div class="tiles">${l}</div>`,F(t,n))}case"paint":{const i=pe(e,t.finishKey),l=e.meta.finishes.map(a=>`<button class="segment ${a.id===i?"is-active":""}"
              data-finish="${t.finishKey}" data-colour-key="${t.key}" data-id="${a.id}">${r(a.label)}</button>`).join("");return v(t,`<span class="field-label">${r(o("ui_finish"))}</span><div class="segmented">${l}</div>
         <span class="field-label">${r(o("ui_colour"))}</span>${Q(e,t.key,t.finishKey)}`,C(e,H(e,t.key),t,n))}case"swatch":{const i=e.current[t.key],l=e.meta.colours.map(c=>`<button class="swatch ${c.id===i?"is-active":""}" style="background:${c.hex}"
              title="${r(c.label)}" data-set="${t.key}" ${V(c.id)}></button>`).join(""),a=(s=e.meta.colours.find(c=>c.id===i))==null?void 0:s.label;return v(t,`<div class="swatches">${l}</div>${a?`<p class="hint">${r(a)}</p>`:""}`,C(e,H(e,t.key),t,n))}case"wheels":{const i=p(t.types).map(d=>`<button class="chip ${d.id===e.rimType?"is-active":""}" data-rim-type="${d.id}">${r(d.label)}</button>`).join(""),l=e.rimType===null?void 0:e.rims[e.rimType],a=e.original.wheels===e.rimType,c=d=>{const q=e.current.wheels===e.rimType&&e.current.modFrontWheels===d.value,De=a&&e.original.modFrontWheels===d.value?`<small class="is-installed">${r(o("desc_installed"))}</small>`:`<small>${x(_(e,"wheels"))}</small>`;return M(`data-rim="${d.value}"`,d.label,De,q)};let u=`<div class="tiles">${(l??[]).map(c).join("")}</div>`;return l?l.length<=1&&(u=`<div class="empty">${r(o("ui_no_rims"))}</div>`):u=`<div class="empty">${r(o("ui_loading_rims"))}</div>`,v(t,`<div class="chips">${i}</div>${u}`,F(t,n))}case"smoke":{const i=e.current.modSmokeEnabled===!0,l=[!1,!0].map(c=>{const u=o(c?"ui_smoke_coloured":"ui_smoke_stock");return M(`data-set="modSmokeEnabled" ${V(c)}`,u,$e(e,"modSmokeEnabled",c),i===c)}).join(""),a=i?Q(e,"tyreSmokeColor",null,ve):"";return v(t,`<div class="tiles">${l}</div>${a}`,C(e,"tyreSmoke",t,n))}case"xenon":{const i=e.current.modXenon===!0,l=p(t.options).map(a=>{const c=a.id===-1?!i:i&&e.current.xenonColor===a.id;return M(`data-xenon="${a.id}"`,a.label,"",c,a.hex)}).join("");return v(t,`<div class="tiles">${l}</div>`,C(e,"xenon",t,n))}case"neon":{const i=p(e.current.neonEnabled),l=pt.map((c,u)=>{const d=`<small>${r(o(i[u]?"desc_on":"desc_off"))}</small>`;return M(`data-neon="${u}"`,o(c),d,i[u]===!0)}).join(""),a=`<span class="field-label">${r(o("ui_colour"))}</span>${Q(e,"neonColor",null,ve)}`;return v(t,`<div class="tiles">${l}</div>${a}`,C(e,"neon",t,n))}case"extras":{const i=D(e.current),l=p(t.ids).map(c=>{const u=i[String(c)]===0,d=`<small>${r(o(u?"ui_fitted":"ui_removed"))}</small>`;return M(`data-extra="${c}"`,o("ui_extra_n",c),d,u)}).join(""),a=r(o("ui_extra_hint",x(_(e,"extra"))));return v(t,`<div class="tiles">${l}</div><p class="hint">${a}</p>`,F(t,n))}}}function qe(e,t){f("nav").innerHTML=e.meta.categories.map(n=>{const s=n.sections.some(i=>me(i,t));return`
        <button class="nav-tab ${n.id===e.category?"is-active":""}" data-category="${n.id}">
          ${s?'<span class="nav-dot"></span>':""}
          ${h(n.icon,18)}
          <span>${r(n.label)}</span>
        </button>`}).join("")}function yt(e){return e.damaged?`
    <section class="repair">
      <span class="repair-mark">${h("wrench",18)}</span>
      <div class="grow">
        <strong>${r(o("ui_damaged"))}</strong>
        <small>${r(o("ui_repair_it"))}</small>
      </div>
      <button class="btn btn--primary" data-action="repair" ${e.busy?"disabled":""}>
        ${e.busy?h("loader",14,2.4,"spin"):""}${r(o("ui_repair_price",x(e.meta.repairPrice||0)))}
      </button>
    </section>`:""}function vt(e,t){const n=f("body"),s=e.meta.categories.find(a=>a.id===e.category),i=n.dataset.category===e.category?n.scrollTop:0,l=((s==null?void 0:s.sections)??[]).map(a=>gt(e,a,t));n.dataset.category=e.category??"",n.innerHTML=yt(e)+l.join(""),n.scrollTop=i}function R(e,t){const n=Object.keys(t).length,s=he(e,t);let i=o(e.meta.billsOwner?"ui_who_pick":"ui_who_bank");e.meta.requests&&(i=o("ui_who_request"));let l=n===0?o("ui_no_changes"):o(n===1?"ui_change_one":"ui_change_many",n,i);e.damaged&&(l=o("ui_repair_before")),e.waiting&&(l=o("ui_waiting_for",e.waiting));let a=o(e.meta.billsOwner?"ui_bill_install":"ui_pay_install");s===0&&(a=o("ui_install")),e.meta.requests&&(a=o("ui_request_install"));const c=n>0&&!e.busy,u=c&&!e.damaged;f("foot").innerHTML=`
    <div class="foot-row">
      <div class="total">
        <strong>${x(s)}</strong>
        <small class="${e.waiting||e.damaged?"is-waiting":""}">${r(l)}</small>
      </div>
      <button class="btn btn--ghost" data-action="reset" ${c?"":"disabled"}>${h("reset",14,2.4)}${r(o("ui_reset"))}</button>
      <button class="btn btn--primary" data-action="apply" ${u?"":"disabled"}>
        ${e.busy?h("loader",14,2.4,"spin"):h("wrench",14,2.4)}${r(a)}
      </button>
    </div>`}function $t(e){return e===null?`<div class="empty">${r(o("ui_looking"))}</div>`:e.length===0?`<div class="empty">${r(o("ui_nobody"))}</div>`:e.map(t=>`
        <button class="tile payer" data-payer="${t.id}" data-name="${r(t.name)}">
          <span class="tile-head">
            <strong>${r(t.name)}</strong>
            ${t.owner?`<span class="pill pill--accent">${r(o("ui_owner"))}</span>`:""}
            ${t.you?`<span class="pill pill--muted">${r(o("ui_you"))}</span>`:""}
          </span>
          <small>${r(o(t.you?"ui_pay_own":"ui_send_bill"))}</small>
        </button>`).join("")}function ae(e){const t=f("picker"),n=e==null?void 0:e.picking;if(!e||!n){t.hidden=!0,t.innerHTML="";return}t.hidden=!1,t.innerHTML=`
    <section class="card picker-card">
      <header class="card-head">
        <h2>${r(o("ui_who_pays",x(he(e,X(e)))))}</h2>
        <button class="key-btn" data-action="cancel-pick">${r(o("ui_cancel"))}</button>
      </header>
      <div class="card-body">
        <p class="hint">${r(o("ui_within",e.meta.payerDistance??5))}</p>
        <div class="payers">${$t(n.list)}</div>
      </div>
    </section>`}async function _t(e){e.picking={list:null},ae(e);const t=p(await m("customs:payers"));b!==e||!e.picking||(e.picking.list=t,ae(e))}function le(e){e.picking=null,ae(e)}function g(e){const t=X(e);qe(e,t),vt(e,t),R(e,t)}async function kt(e){e.busy=!0,g(e);const t=await ue("customs:repair");b===e&&(e.busy=!1,t.ok&&(e.damaged=!1),t.msg&&J(t.msg,t.ok),g(e))}async function Pe(e,t){e.rimType=t,e.rims[t]||(g(e),e.rims[t]=p(await m("customs:rims",{type:t}))),b===e&&g(e)}function Fe(e,t){var l;e.category=t;const n=((l=e.meta.categories.find(a=>a.id===t))==null?void 0:l.sections)??[],s=n[0];Ae(s?He(s):"overview");const i=n.find(a=>a.type==="wheels");if((i==null?void 0:i.type)==="wheels"&&e.rimType===null){const a=p(i.types),c=a.find(u=>u.id===e.current.wheels)??a[0];if(c){Pe(e,c.id);return}}g(e)}function xt(e){var a,c;const t=p(e.categories).map(u=>({...u,sections:p(u.sections)})),n={...e,categories:t,colours:p(e.colours),finishes:p(e.finishes),bike:t.some(u=>u.sections.some(d=>d.type==="wheels"&&d.bike===!0))},s={...e.values??{}};s.extras=Array.isArray(s.extras)||!s.extras?{}:s.extras;const i={meta:n,original:S(s),current:S(s),category:null,rimType:null,rims:{},busy:!1,waiting:null,picking:null,damaged:n.damaged===!0};b=i,se="overview",y.innerHTML=`
    <header class="panel-head">
      ${oe()}
      <div class="panel-title">
        <h1>${r(n.shop)}</h1>
        <p>${r((a=n.vehicle)==null?void 0:a.name)} · ${r(String(((c=n.vehicle)==null?void 0:c.plate)??"").trim())}</p>
      </div>
      <button class="key-btn" data-action="close">${r(o("ui_esc"))}</button>
    </header>
    <nav class="nav" id="nav"></nav>
    <main class="body" id="body"></main>
    <footer class="foot" id="foot"></footer>
    <div class="picker" id="picker" hidden></div>`,y.hidden=!1,L.hidden=!1,ne.textContent=o("ui_cam_hint"),ne.hidden=!1;const l=n.categories[0];l&&Fe(i,l.id)}function wt(){b=null,y.hidden=!0,L.hidden=!0,ne.hidden=!0,y.innerHTML=""}async function _e(e,t){const n=X(e);if(!Object.keys(n).length||e.busy)return;if(e.meta.billsOwner&&!e.meta.requests&&he(e,n)>0&&!t){await _t(e);return}e.busy=!0,R(e,n);const s=await ue("customs:apply",{changes:n,payer:t==null?void 0:t.id});if(b===e){if(s.msg&&J(s.msg,s.ok),s.ok&&s.requested){m("customs:close");return}if(s.ok&&s.waiting){e.waiting=(t==null?void 0:t.name)||o("ui_them"),R(e,n);return}e.busy=!1,s.ok&&(e.original=S(e.current)),g(e)}}function Mt(e){const t=b;t&&(t.busy=!1,t.waiting=null,e.ok&&(t.original=S(t.current)),e.msg&&J(e.msg,e.ok),g(t))}function Tt(){const e=b;return e?(e.picking?le(e):m("customs:close"),!0):!1}function St(e,t){if(t.set)$(e,{[t.set]:JSON.parse(t.value??"null")});else if(t.rim!==void 0)$(e,{wheels:e.rimType??0,modFrontWheels:Number(t.rim)});else if(t.finish&&t.colourKey)$(e,{[t.finish]:Number(t.id),[t.colourKey]:ie(e,t.colourKey)});else if(t.rgbPreset&&t.hex){const n={[t.rgbPreset]:ce(t.hex)};t.finishKey&&(n[t.finishKey]=pe(e,t.finishKey)),$(e,n)}else if(t.xenon!==void 0){const n=Number(t.xenon);$(e,n===-1?{modXenon:!1}:{modXenon:!0,xenonColor:n})}else if(t.neon!==void 0){const n=p(e.current.neonEnabled).slice(0,4);for(;n.length<4;)n.push(!1);n[Number(t.neon)]=!n[Number(t.neon)],$(e,{neonEnabled:n,neonColor:ie(e,"neonColor")})}else if(t.extra!==void 0){const n={...D(e.current)};n[t.extra]=n[t.extra]===0?1:0,$(e,{extras:n})}else return!1;return!0}y.addEventListener("pointerdown",e=>{const t=e.target.closest("[data-focus]");b&&(t!=null&&t.dataset.focus)&&Ae(t.dataset.focus)});y.addEventListener("click",e=>{const t=b;if(!t)return;const n=e.target.closest("button");if(!n||n.disabled)return;const s=n.dataset;if(s.action==="close"){m("customs:close");return}t.busy||(s.action==="cancel-pick"?le(t):s.payer!==void 0?(le(t),_e(t,{id:Number(s.payer),name:s.name??""})):s.action==="apply"?_e(t):s.action==="repair"?kt(t):s.action==="reset"?(t.current=S(t.original),m("customs:reset"),g(t)):s.category?Fe(t,s.category):s.rimType!==void 0?Pe(t,Number(s.rimType)):St(t,s)&&g(t))});y.addEventListener("input",e=>{const t=b,n=e.target,s=n.dataset.hexInput;if(!t||!s)return;if(t.busy){g(t);return}const i=ft.exec(n.value.trim());if(n.classList.toggle("is-invalid",!i),!i)return;const l=`#${i[1].toLowerCase()}`,a={[s]:ce(l)};n.dataset.finishKey&&(a[n.dataset.finishKey]=pe(t,n.dataset.finishKey)),$(t,a);const c=y.querySelector(`[data-rgb-preview="${s}"]`);c&&(c.style.background=l);const u=X(t);qe(t,u),R(t,u)});y.addEventListener("change",e=>{b&&e.target.dataset.hexInput&&g(b)});let T=null,N={dx:0,dy:0,zoom:0},Z=!1;function Ie(){Z||(Z=!0,requestAnimationFrame(()=>{const e=N;Z=!1,N={dx:0,dy:0,zoom:0},(e.dx||e.dy||e.zoom)&&m("customs:camera",e)}))}L.addEventListener("mousedown",e=>{T={x:e.clientX,y:e.clientY},L.classList.add("is-dragging")});window.addEventListener("mousemove",e=>{T&&(N.dx+=e.clientX-T.x,N.dy+=e.clientY-T.y,T={x:e.clientX,y:e.clientY},Ie())});window.addEventListener("mouseup",()=>{T=null,L.classList.remove("is-dragging")});L.addEventListener("wheel",e=>{N.zoom+=Math.sign(e.deltaY),Ie()});const ke={requested:"pill--muted",billed:"pill--accent",paid:"pill--ok",installing:"pill--accent",fitted:"pill--warn"},A=f("tablet");let k=null;function Lt(e){const t=Math.max(0,Math.round((Date.now()-e)/6e4));if(t<1)return o("ui_just_now");if(t<60)return o("ui_mins_ago",t);const n=Math.round(t/60);return n<24?o("ui_hours_ago",n):o("ui_days_ago",Math.round(n/24))}function Et(e){return e.status==="requested"&&!e.online?o("ui_note_offline"):e.status==="billed"?o("ui_note_billed"):e.status==="paid"?o("ui_note_paid"):e.status==="installing"?o("ui_note_installing",e.installer??""):e.status==="fitted"?o("ui_note_fitted",e.installer??""):o("ui_note_requested",Lt(e.createdAt))}function Ct(e,t){const n=t.status in ke?t.status:"requested",s=e.busy===t.id,i=p(t.parts).map(a=>`<li>${r(a)}</li>`).join("");let l="";return t.status==="requested"&&(l=`
      <button class="btn btn--ghost" data-decline="${t.id}" ${e.busy?"disabled":""}>${r(o("ui_decline"))}</button>
      <button class="btn btn--primary" data-bill="${t.id}" ${e.busy||!t.online?"disabled":""}>
        ${s?h("loader",14,2.4,"spin"):h("wrench",14,2.4)}${r(o("ui_bill_customer"))}
      </button>`),`
    <section class="card request">
      <header class="card-head">
        <h2>${r(t.customer)}<span class="request-sub">${r(t.model||o("ui_vehicle"))} · ${r(t.plate)}</span></h2>
        <span class="pill ${ke[n]}">${r(o(`ui_status_${n}`))}</span>
      </header>
      <div class="card-body">
        <ul class="parts">${i}</ul>
        <div class="request-foot">
          <div class="total">
            <strong>${x(t.total)}</strong>
            <small>${r(Et(t))}</small>
          </div>
          ${l}
        </div>
      </div>
    </section>`}function z(e){const t=e.list,n=f("tabletBody"),s=n.scrollTop;let i=`<div class="empty">${r(o("ui_loading_requests"))}</div>`;t&&t.length===0?i=`<div class="empty">${r(o("ui_no_requests"))}</div>`:t&&(i=t.map(a=>Ct(e,a)).join(""));const l=(t??[]).filter(a=>a.status==="paid"||a.status==="billed").length;f("tabletSub").textContent=t?o("ui_tablet_sub",t.length,l):o("ui_tablet_brand"),f("tabletTime").textContent=new Date().toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"}),n.innerHTML=i,n.scrollTop=s}function Ot(){const e={list:null,busy:null};k=e,A.innerHTML=`
    <div class="device">
      <span class="device-cam"></span>
      <div class="device-screen">
        <div class="device-bar">
          <span id="tabletTime"></span>
          <span>${r(o("ui_tablet_brand"))}</span>
        </div>
        <header class="panel-head">
          ${oe()}
          <div class="panel-title">
            <h1>${r(o("ui_pending_installs"))}</h1>
            <p id="tabletSub"></p>
          </div>
          <button class="key-btn" data-tablet="refresh" title="${r(o("ui_refresh"))}">${h("reset",13,2.4)}</button>
          <button class="key-btn" data-tablet="close">${r(o("ui_esc"))}</button>
        </header>
        <main class="tablet-body" id="tabletBody"></main>
      </div>
    </div>`,A.hidden=!1,z(e)}function jt(){k=null,A.hidden=!0,A.innerHTML=""}function Ht(e){k&&(k.list=p(e),z(k))}function Nt(){return k?(m("tablet:close"),!0):!1}A.addEventListener("click",async e=>{const t=k;if(!t)return;const n=e.target.closest("button");if(!n||n.disabled)return;const s=n.dataset;if(s.tablet==="close"){m("tablet:close");return}if(s.tablet==="refresh"){m("tablet:refresh");return}const i=Number(s.bill??s.decline);if(!i||t.busy)return;t.busy=i,z(t);const l=await ue(s.bill?"tablet:bill":"tablet:decline",{id:i});k===t&&(t.busy=null,l.msg&&J(l.msg,l.ok),z(t))});const ee=f("frame");function Ke(){const e=Math.min(innerWidth/1920,innerHeight/1080);ee.style.width=`${innerWidth/e}px`,ee.style.height=`${innerHeight/e}px`,ee.style.transform=`scale(${e})`}async function At(){for(;;)try{const e=await m("ready");ze(e.locale);return}catch{await Ue(1e3)}}window.addEventListener("keydown",e=>{e.key==="Escape"&&!dt()&&!Nt()&&Tt()});window.addEventListener("message",e=>{const{action:t,data:n}=e.data??{};switch(t){case"inspect":Xe(n);break;case"customs:open":xt(n);break;case"customs:close":wt();break;case"customs:billed":Mt(n??{ok:!1});break;case"tablet:open":Ot();break;case"tablet:list":Ht(n);break;case"tablet:close":jt();break;case"install:start":ct(n??{});break;case"install:close":ut();break}});window.addEventListener("resize",Ke);Ke();At();
