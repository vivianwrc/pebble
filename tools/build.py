"""Baut aus Pebble.html die Webseite (index.html) für GitHub Pages."""
import sys,datetime,re
src=sys.argv[1] if len(sys.argv)>1 else 'Pebble.html'
out=sys.argv[2] if len(sys.argv)>2 else 'index.html'
s=open(src,encoding='utf8').read()
head=('<link rel="manifest" href="manifest.webmanifest"><link rel="icon" href="favicon.png"><link rel="apple-touch-icon" href="apple-touch-icon.png">'
 '<meta name="theme-color" content="#f5efe6"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="mobile-web-app-capable" content="yes">'
 '<meta name="apple-mobile-web-app-title" content="Pebble"><meta name="description" content="Pebble – gemütliches Bau- und Wohnspiel mit Pinguin.">'
 '<script src="vendor/supabase.js"></script><script src="config.js"></script>'
 '<script>try{var C=window.PEBBLE_CONFIG||{};if(window.supabase&&C.supabaseUrl&&C.supabaseKey)window.PEBBLE_SB=window.supabase.createClient(C.supabaseUrl,C.supabaseKey,{auth:{persistSession:true,detectSessionInUrl:true,storageKey:"pebble-auth"}})}catch(e){}</script>')
i=s.index('</head>');s=s[:i]+head+s[i:]
s=s.replace('<title>Pebble</title>','<title>Pebble</title>',1)
open(out,'w',encoding='utf8').write(s)
import os
open(os.path.join(os.path.dirname(os.path.abspath(out)),'version.txt'),'w').write(datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M')+'\n')
print('ok',len(s))
