# Erzeugt impressum.html, datenschutz.html, agb.html und legal.css im Webseiten-Ordner.
# Angaben zum Betreiber stehen in legal.json: {"name": "...", "adresse": ["Straße 1", "12345 Ort"], "mail": "..."}
import json,os,html
d=os.path.dirname(os.path.abspath(__file__));root=os.path.abspath(os.path.join(d,'..','..'))
c=json.load(open(os.path.join(d,'legal.json'),encoding='utf-8'))
rep={'{{NAME}}':html.escape(c['name']),'{{ADRESSE}}':'<br>'.join(html.escape(x) for x in c['adresse']),'{{MAIL}}':html.escape(c['mail']),'{{VERTRETEN}}':html.escape(c['vertreten'])}
for f in ['impressum.html','datenschutz.html','agb.html']:
    s=open(os.path.join(d,f),encoding='utf-8').read()
    for k,v in rep.items():s=s.replace(k,v)
    assert '{{' not in s, f
    open(os.path.join(root,f),'w',encoding='utf-8').write(s)
open(os.path.join(root,'legal.css'),'w').write(open(os.path.join(d,'style.css')).read())
print('ok')
