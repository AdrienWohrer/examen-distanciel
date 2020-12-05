#!/usr/bin/python
# -*- coding: utf-8 -*-

# usage:
# python random_params.py etudiant1.tex etudiant2.tex ...
# 
# génère des données autant de fois que requis, et les sauve dans chacun
# des fichiers tex spécifiés.

# Remarque: l'intérêt d'utiliser python (plutôt que ruby comme les autres scripts) est de bénéficier des nombreuses fonctionalités numériques du module numpy

import sys
import numpy as np

from time import sleep

if len(sys.argv) == 1:
    sys.argv += ["defaultparams.tex"]  # (fichier produit par défaut lorsqu'on appelle la fonction sans argument)

###############################################################

   
        
# Fonction de génération pour un seul étudiant:

def generate(outputtex):
    with open(outputtex, 'w') as fid:
        fid.write('%% Généré automatiquement avec le script python random_params.py\n');
        
        ######## Fonctions d'aide                 
         
        # Stocker une variable latex appelée \<valname> (avec le backslash devant)
        # dans le fichier outputtex, ayant la valeur <val>.
        
        def stock(valname, val):
            fid.write("\\def\\%s{%s}\n"%(valname,str(val)))
            # https://www.geeksforgeeks.org/string-formatting-in-python/
            # todo, gérer la précision pour les float
            # todo, gérer le cas où val est une liste ou un tuple
        
        # Version groupée (voir exemple d'utilisation ci-dessous)
        # En pratique, dico sera "locals()", la liste de toutes les variables locales existantes
        
        def stockfast(dico, selectnames):
            selectlist = selectnames.split()
            for key in dico:
                if key in selectlist:
                    stock(key,dico[key])            
                
        ######## Génération et stockage des paramètres pour l'examen:

        vd = np.random.randint(15,25)
        vq = np.random.randint(15,25)
        vr = np.random.randint(0,3)
        vc = vq*vd + vr
        ismultiple = (vr==0)

#        # stockage basique
#        stock("vd",vd)
#        etc.

        # stockage groupé
        stockfast(locals(),"vc vd vq vr ismultiple")
        

###############################################################
    
# Appel de la fonction sur tous les étudiants:

for outputtex in sys.argv[1:]:
    generate(outputtex)


