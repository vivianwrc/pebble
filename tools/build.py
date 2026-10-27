"""Baut aus Pebble.html die Webseite (index.html) für GitHub Pages."""
import sys,datetime,re
VER=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M')
src=sys.argv[1] if len(sys.argv)>1 else 'Pebble.html'
out=sys.argv[2] if len(sys.argv)>2 else 'index.html'
s=open(src,encoding='utf8').read()
head=('<link rel="manifest" href="manifest.webmanifest"><link rel="icon" href="favicon.png"><link rel="apple-touch-icon" href="apple-touch-icon.png">'
 '<meta name="theme-color" content="#f5efe6"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="mobile-web-app-capable" content="yes">'
 '<meta name="apple-mobile-web-app-title" content="Pebble Town"><meta name="description" content="Pebble – gemütliches Bau- und Wohnspiel mit Pinguin.">'
 '<script>window.PEBBLE_VER="'+VER+'";(function(){function chk(boot){fetch("version.txt?t="+Date.now(),{cache:"no-store"}).then(function(r){return r.text()}).then(function(v){v=v.trim();if(!v||v<=window.PEBBLE_VER)return;if(boot&&!/[?&]v=/.test(location.search)){location.replace(location.pathname+"?v="+v);return}if(document.getElementById("pbUpd"))return;var b=document.createElement("button");b.id="pbUpd";b.textContent="Neue Version da – tippen zum Laden";b.style.cssText="position:fixed;left:50%;top:12px;transform:translateX(-50%);z-index:9999;border:0;border-radius:99px;padding:10px 18px;background:#5b3a24;color:#fff;font:800 14px Nunito,system-ui,sans-serif;box-shadow:0 6px 18px rgba(0,0,0,.25);cursor:pointer";b.onclick=function(){location.replace(location.pathname+"?v="+v)};document.body.appendChild(b)}).catch(function(){})}chk(true);setInterval(function(){chk(false)},300000);document.addEventListener("visibilitychange",function(){if(!document.hidden)chk(false)})})();</script>'
 '<script>if("serviceWorker" in navigator)addEventListener("load",function(){navigator.serviceWorker.register("sw.js").catch(function(){})})</script>'
 '<script src="vendor/supabase.js"></script><script src="config.js"></script>'
 '<script>try{var C=window.PEBBLE_CONFIG||{};if(window.supabase&&C.supabaseUrl&&C.supabaseKey)window.PEBBLE_SB=window.supabase.createClient(C.supabaseUrl,C.supabaseKey,{auth:{persistSession:true,detectSessionInUrl:true,storageKey:"pebble-auth"}})}catch(e){}</script>')
i=s.index('</head>');s=s[:i]+head+s[i:]
s=s.replace('<title>Pebble</title>','<title>Pebble</title>',1)
open(out,'w',encoding='utf8').write(s)
import os
open(os.path.join(os.path.dirname(os.path.abspath(out)),'version.txt'),'w').write(VER+'\n')
print('ok',len(s))
