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
import numpy as np      # Numpy
import numbers          # Numeric abstract base classes
import re               # Regular expressions


if len(sys.argv) == 1:
    sys.argv += ["defaultparams.tex"]  # (fichier produit par défaut lorsqu'on appelle la fonction sans argument)


###############################################################
### Génération du .tex pour chaque étudiant


for outputtex in sys.argv[1:]:
    with open(outputtex, 'w') as fid:
        fid.write('%% Généré automatiquement avec le script python random_params.py\n');
        
        ######## Fonctions d'aide                 
         
        # conversion en str, traitant les "float entier" comme des int (fait automatiquement en python 3)
        
        def mystr(val,prec=2):
            if isinstance(val,numbers.Number):
                val = float(val)
                if val.is_integer():
                    val = int(val)
                else:
                    val = round(val,prec)
            return str(val)
        
        # Stocker une variable latex appelée \<valname> (avec le backslash devant),
        # dans le fichier outputtex, ayant la valeur <val>.
        # prec = nombre de décimales conservées (uniquement pour les nombres non entiers)
        
        def stock(valname, val, prec=2):
            fid.write("\\def\\%s{%s}\n"%(valname,mystr(val,prec)))
        
        # Version groupée (voir exemple d'utilisation ci-dessous)
        # En pratique, dico sera "locals()", la liste de toutes les variables locales existantes
        
        def stockfast(dico, selectnames):
            selectlist = re.split('[ ,]+',selectnames)      # split par " " ou par ","
            for key in dico:
                if key in selectlist:
                    stock(key,dico[key])            
        
        # Convertir une liste (ou np.array) en une string avec un séparateur spécifié
        
        def list2str(liste, sep=","):
            return sep.join([mystr(x) for x in liste])
         
        
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
        


