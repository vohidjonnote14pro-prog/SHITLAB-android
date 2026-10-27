const C="shitlab-8a29b0bf";const CORE=["./","index.html","manifest.webmanifest","apple-touch-icon.png","icon-192.png","icon-512.png","icon-maskable.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(C).then(c=>c.addAll(CORE)).then(()=>self.skipWaiting()));});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==C).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));});
self.addEventListener("fetch",e=>{const u=new URL(e.request.url);if(e.request.method!=="GET"||u.origin!==location.origin)return;
 if(e.request.mode==="navigate"||u.pathname.endsWith("/")||u.pathname.endsWith("index.html")){e.respondWith(fetch(e.request).then(r=>{const cp=r.clone();caches.open(C).then(c=>c.put("index.html",cp));return r;}).catch(()=>caches.match("index.html")));return;}
 e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request)));});
