#!/bin/bash

#################################################
# Script de restauration des personnalisations Viveo
# À exécuter après chaque mise à jour de Jellyfin
#################################################

set -e  # Arrêt en cas d'erreur

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  Restauration des personnalisations Viveo${NC}"
echo -e "${GREEN}==================================================${NC}\n"

# Chemins
WEB_DIR="/usr/share/jellyfin/web"
INDEX_FILE="$WEB_DIR/index.html"
BACKUP_DIR="$WEB_DIR/../viveo-backup-$(date +%Y%m%d-%H%M%S)"
SOURCE_FAVICON="/usr/share/jellyfin/web_/favicon.ico"
SOURCE_BANNER="/usr/share/jellyfin/web_/assets/img/banner-dark.png"
SOURCE_AVATARS="/usr/share/jellyfin/web_/avatars"
SOURCE_MONITOR="/usr/share/jellyfin/web_/monitoruserid.js"
SOURCE_HOLIDAYS="/usr/share/jellyfin/web_/holidays.js"

# Vérifications préalables
if [ ! -f "$INDEX_FILE" ]; then
    echo -e "${RED}❌ Erreur: $INDEX_FILE n'existe pas${NC}"
    exit 1
fi

if [ ! -d "$WEB_DIR" ]; then
    echo -e "${RED}❌ Erreur: Le répertoire $WEB_DIR n'existe pas${NC}"
    exit 1
fi

# Vérifier si les modifications sont déjà appliquées
if grep -q "Viveo" "$INDEX_FILE" && grep -q "sizeRequestIframe" "$INDEX_FILE"; then
    echo -e "${YELLOW}⚠️  Les modifications semblent déjà appliquées.${NC}"
    read -p "Voulez-vous quand même continuer ? (o/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
        echo -e "${YELLOW}Opération annulée.${NC}"
        exit 0
    fi
fi

# Créer le backup
echo -e "${YELLOW}📦 Création du backup dans $BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"
cp -r "$WEB_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✓ Backup créé${NC}\n"

# Fonction pour appliquer les modifications au HTML
# Utilise Python pour être compatible avec les fichiers HTML minifiés (une seule ligne)
apply_html_modifications() {
    echo -e "${YELLOW}📝 Application des modifications au HTML...${NC}"

    python3 - "$INDEX_FILE" <<'PYEOF'
import sys, re
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

# 1. application-name : Jellyfin → Viveo (première occurrence uniquement)
text = text.replace('content="Jellyfin">', 'content="Viveo">', 1)

# 2. <title>
text = text.replace('<title>Jellyfin</title>', '<title>Viveo</title>')

# 3. Favicon : remplacer la version hashée par favicon.ico
text = re.sub(
    r'<link rel="shortcut icon" href="favicon\.[a-f0-9]+\.ico">',
    '<link rel="shortcut icon" href="favicon.ico">',
    text
)

# 4. Injecter les scripts Viveo avant </body> (idempotent)
if 'monitoruserid.js' not in text:
    inject = (
        '<script defer src="monitoruserid.js"></script>'
        '<script defer src="holidays.js"></script>'
        '<script>'
        'function sizeRequestIframe(){'
        'try{'
        'const tab=document.getElementById("requestsTab");'
        'const sections=tab?tab.querySelector(".sections"):null;'
        'const iframe=tab?tab.querySelector("iframe.requestIframe"):null;'
        'if(!tab||!sections||!iframe)return;'
        'const visible=getComputedStyle(tab).display!=="none"&&tab.offsetParent!==null;'
        'iframe.style.display=visible?"block":"none";'
        'if(!visible)return;'
        'const rect=sections.getBoundingClientRect();'
        'const vv=window.visualViewport;'
        'const vh=vv?vv.height:window.innerHeight;'
        'const vw=vv?vv.width:window.innerWidth;'
        'const top=Math.max(rect.top,0);'
        'iframe.style.top=top+"px";'
        'iframe.style.height=Math.max(vh-top,0)+"px";'
        'iframe.style.width=vw+"px";'
        '}catch(e){}'
        '}'
        'window.sizeRequestIframe=sizeRequestIframe;'
        'const createRequestTab=()=>{'
        'console.log("Creating request tab");'
        'const title=document.createElement("div");'
        'title.classList.add("emby-button-foreground");'
        'title.innerText="Requests";'
        'const button=document.createElement("button");'
        'button.type="button";'
        'button.is="empty-button";'
        'button.classList.add("emby-tab-button","emby-button","lastFocused");'
        'button.setAttribute("data-index","2");'
        'button.setAttribute("id","requestTab");'
        'button.appendChild(title);'
        'button.addEventListener("click",()=>setTimeout(sizeRequestIframe,50));'
        '(function e(){'
        'const tabb=document.querySelector(".emby-tabs-slider");'
        'if(tabb&&!document.querySelector("#requestTab")){'
        'tabb.appendChild(button);'
        'const tabEl=document.getElementById("requestsTab");'
        'if(tabEl){new MutationObserver(()=>sizeRequestIframe()).observe(tabEl,{attributes:true,attributeFilter:["style","class"]});}'
        '}else if(!tabb){setTimeout(e,500);}'
        '})();'
        '};'
        'window.addEventListener("popstate",()=>{createRequestTab();setTimeout(sizeRequestIframe,100);});'
        'window.addEventListener("resize",sizeRequestIframe);'
        'window.addEventListener("orientationchange",sizeRequestIframe);'
        'window.addEventListener("requests:ready",sizeRequestIframe);'
        '</script>'
    )
    text = text.replace('</body>', inject + '</body>')

path.write_text(text)
path.chmod(0o644)
PYEOF

    echo -e "${GREEN}✓ Modifications HTML appliquées${NC}\n"
}

# Copier le favicon personnalisé
copy_favicon() {
    if [ -f "$SOURCE_FAVICON" ]; then
        echo -e "${YELLOW}🎨 Copie du favicon personnalisé...${NC}"
        cp "$SOURCE_FAVICON" "$WEB_DIR/favicon.ico"
        chmod 644 "$WEB_DIR/favicon.ico"
        echo -e "${GREEN}✓ Favicon copié${NC}\n"
    else
        echo -e "${YELLOW}⚠️  Favicon source non trouvé: $SOURCE_FAVICON${NC}\n"
    fi
}

# Copier le banner personnalisé (remplace les versions hashées si présentes)
copy_banner() {
    if [ ! -f "$SOURCE_BANNER" ]; then
        echo -e "${YELLOW}⚠️  Banner source non trouvé: $SOURCE_BANNER${NC}\n"
        return
    fi

    echo -e "${YELLOW}🖼️  Copie du logo personnalisé...${NC}"

    BANNER_LIGHT_HASH=$(find "$WEB_DIR" -maxdepth 1 -name "banner-light.*.png" -type f | head -1)
    BANNER_DARK_HASH=$(find "$WEB_DIR" -maxdepth 1 -name "banner-dark.*.png" -type f | head -1)

    if [ -n "$BANNER_LIGHT_HASH" ] && [ -f "$BANNER_LIGHT_HASH" ]; then
        cp "$SOURCE_BANNER" "$BANNER_LIGHT_HASH"
        chmod 644 "$BANNER_LIGHT_HASH"
        echo -e "${GREEN}✓ Banner-light copié: $(basename "$BANNER_LIGHT_HASH")${NC}"
    fi

    if [ -n "$BANNER_DARK_HASH" ] && [ -f "$BANNER_DARK_HASH" ]; then
        cp "$SOURCE_BANNER" "$BANNER_DARK_HASH"
        chmod 644 "$BANNER_DARK_HASH"
        echo -e "${GREEN}✓ Banner-dark copié: $(basename "$BANNER_DARK_HASH")${NC}"
    fi

    mkdir -p "$WEB_DIR/assets/img"
    cp "$SOURCE_BANNER" "$WEB_DIR/assets/img/banner-dark.png"
    chmod 644 "$WEB_DIR/assets/img/banner-dark.png"
    cp "$SOURCE_BANNER" "$WEB_DIR/assets/img/banner-light.png"
    chmod 644 "$WEB_DIR/assets/img/banner-light.png"
    echo -e "${GREEN}✓ Banner copié aussi vers assets/img${NC}\n"
}

# Copier les avatars personnalisés


# Copier le script monitoruserid.js personnalisé
copy_monitor_script() {
    if [ ! -f "$SOURCE_MONITOR" ]; then
        echo -e "${YELLOW}⚠️  Script monitoruserid.js source non trouvé: $SOURCE_MONITOR${NC}\n"
        return
    fi

    echo -e "${YELLOW}🕵️  (pour avatar) Copie de monitoruserid.js...${NC}"
    cp "$SOURCE_MONITOR" "$WEB_DIR/monitoruserid.js"
    chmod 644 "$WEB_DIR/monitoruserid.js"
    echo -e "${GREEN}✓ Script monitoruserid.js copié${NC}\n"
}


# Remplacer le chunk home-html.*.chunk.js avec l'onglet Requests et l'iframe
patch_home_chunk() {
    local chunk
    chunk=$(find "$WEB_DIR" -maxdepth 1 -name "home-html.*.chunk.js" | head -1)

    if [ -z "$chunk" ]; then
        echo -e "${YELLOW}⚠️  Aucun fichier home-html.*.chunk.js trouvé dans $WEB_DIR${NC}\n"
        return
    fi

    echo -e "${YELLOW}🧩 Patch du chunk home-html pour l'onglet Requests...${NC}"

    cat > "$chunk" <<'EOF'
"use strict"; (self.webpackChunk = self.webpackChunk || []).push([[8372], { 5939: function (a, e, t) { t.r(e), e.default = '<div id="indexPage" style="outline:0" data-role="page" data-dom-cache="true" class="page homePage libraryPage allLibraryPage backdropPage pageWithAbsoluteTabs withTabs" data-backdroptype="movie,series,book"><style>:root{--save-gut:max(env(safe-area-inset-left),3.3%)}#requestsTab,#requestsTab>.sections{position:relative;height:100dvh;min-height:100dvh}.requestIframe{display:none;margin:0;padding:0;border:none;position:fixed;left:0;right:0;top:0;width:100vw;height:100dvh;background:transparent;z-index:2}</style><script>setTimeout(()=>{createRequestTab();window.dispatchEvent(new Event("requests:ready"))},500)</script> <div class="tabContent pageTabContent" id="homeTab" data-index="0"> <div class="sections"></div> </div> <div class="tabContent pageTabContent" id="favoritesTab" data-index="1"> <div class="sections"></div> </div> <div class="tabContent pageTabContent" id="requestsTab" data-index="2"> <div class="sections"><iframe class="requestIframe" src="https://vivefind.borrelly-betta.ts.net/"></iframe></div> </div> </div> ' } }]);
EOF

    chmod 644 "$chunk"
    echo -e "${GREEN}✓ Chunk patché: $(basename "$chunk")${NC}\n"
}

# Ajouter un lien "More Avatars" au chunk user-userprofile
patch_user_profile_chunk() {
    local chunk
    chunk=$(find "$WEB_DIR" -maxdepth 1 -name "user-userprofile.*.chunk.js" | head -1)

    if [ -z "$chunk" ]; then
        echo -e "${YELLOW}⚠️  Aucun fichier user-userprofile.*.chunk.js trouvé dans $WEB_DIR${NC}\n"
        return
    fi

    echo -e "${YELLOW}👤 Patch du chunk user-userprofile pour le lien More Avatars...${NC}"

    python3 - <<'PY' "$chunk"
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

anchor = '(0,n.jsx)("a",{href:"/web/avatars/",target:"_self",className:"button-link",style:{marginTop:"0.5em"},children:"More Avatars"})'
old = '(0,n.jsx)(d.A,{type:"button",id:"btnAddImage",className:"raised button-submit hide",title:l.Ay.translate("ButtonAddImage")}),(0,n.jsx)(d.A,{type:"button",id:"btnDeleteImage",className:"raised hide",title:l.Ay.translate("DeleteImage")})]})]}),(0,n.jsx)(f.A,{userId:e})'
new = '(0,n.jsx)(d.A,{type:"button",id:"btnAddImage",className:"raised button-submit hide",title:l.Ay.translate("ButtonAddImage")}),(0,n.jsx)(d.A,{type:"button",id:"btnDeleteImage",className:"raised hide",title:l.Ay.translate("DeleteImage")}),'+anchor+']})]}),(0,n.jsx)(f.A,{userId:e})'

if anchor in text:
    print("More Avatars déjà injecté")
    sys.exit(0)

if old not in text:
    print("Motif introuvable, patch ignoré", file=sys.stderr)
    sys.exit(0)

path.write_text(text.replace(old, new))
print("Patch appliqué")
PY

    echo -e "${GREEN}✓ Chunk user-userprofile patché${NC}\n"
}

# Exécution des modifications
apply_html_modifications
copy_favicon
copy_banner
copy_monitor_script
patch_home_chunk
patch_user_profile_chunk

# Résumé
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  ✅ Restauration terminée avec succès !${NC}"
echo -e "${GREEN}==================================================${NC}\n"

echo -e "Modifications appliquées:"
echo -e "  ✓ Titre changé de 'Jellyfin' à 'Viveo'"
echo -e "  ✓ Nom de l'application changé en 'Viveo'"
echo -e "  ✓ Script de l'onglet Requests ajouté"
echo -e "  ✓ Favicon personnalisé installé"
echo -e "  ✓ Logo personnalisé installé"
echo -e "  ✓ Avatars Script et "changer de profil" initialisé "
echo ""
echo -e "Backup sauvegardé dans: ${YELLOW}$BACKUP_DIR${NC}"
echo ""
echo -e "${YELLOW}💡 Redémarrez Jellyfin pour appliquer les changements:${NC}"
echo -e "   ${GREEN}sudo systemctl restart jellyfin${NC}"
echo ""
