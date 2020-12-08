#!/usr/bin/python
# -*- coding: utf-8 -*-

# usage:
# python random_params.py etudiant1.tex etudiant2.tex ...
# 
# génère des données autant de fois que requis, et les sauve dans chacun
# des fichiers tex spécifiés.

# Remarque: l'intérêt d'utiliser python (plutôt que ruby comme les autres scripts)
# est de bénéficier des nombreuses fonctionalités numériques du module numpy

import sys
import numpy as np
import re
from time import sleep

if len(sys.argv) == 1:
    sys.argv += ["defaultparams.tex"]  # (fichier produit par défaut lorsqu'on appelle la fonction sans argument)

###############################################################


# Fonction de génération pour un seul étudiant:

def generate(outputtex):
    with open(outputtex, 'w') as fid:
        fid.write('%% Généré automatiquement avec le script python random_params.py\n');
        
        ######## Fonctions d'aide                 
         
        # Stocker une variable latex appelée \<valname> (avec le backslash devant),
        # dans le fichier outputtex, ayant la valeur <val>.
        # prec = nombre de décimales conservées (uniquement pour les nombres non entiers)
        
        def stock(valname, val, prec=2):
            if type(val) == float: 
                if val.is_integer():
                    val = int(val)
                else:
                    val = round(val,prec)
            fid.write("\\def\\%s{%s}\n"%(valname,str(val)))
        
        # Version groupée (voir exemple d'utilisation ci-dessous)
        # En pratique, dico sera "locals()", la liste de toutes les variables locales existantes
        
        def stockfast(dico, selectnames):
            selectlist = re.split('[ ,]+',selectnames)      # split par " " ou par ","
            for key in dico:
                if key in selectlist:
                    stock(key,dico[key])            
        
        # Convertir une liste (ou np.array) en une string avec un séparateur spécifié
        
        def list2str(liste, sep=","):
            return sep.join([str(x) for x in liste])
         
        
        ######## Génération et stockage des paramètres pour l'examen:

        vd = np.random.randint(15,25)
        vq = np.random.randint(15,25)
        vr = np.random.randint(0,3)
        vc = vq*vd + vr
        ismultiple = (vr==0)

#        # stockage basique
#        stock("vd",vd)
#        etc.

        # stockage groupé (on peut séparer par des espaces ou virgules indifféremment)
        stockfast(locals(),"vc,vd,vq, vr ismultiple")
        

###############################################################
    
# Appel de la fonction sur tous les étudiants:

for outputtex in sys.argv[1:]:
    generate(outputtex)


