# examen-distanciel
Génération et envoi de sujets latex individualisés pour les examens à distance

Ensemble de scripts sous linux, permettant:

- d'ENVOYER par mail un sujet individualisé à chaque étudiant

- de PARCOURIR plus rapidement les rendus étudiants + corrections lors de la correction

- de GÉNÉRER des sujets individualisés, avec l'une et/ou l'autre de deux approches:
    1) écrire des versions différentes et les assigner au hasard aux étudiants
    2) personnaliser chaque sujet avec de la génération aléatoire de paramètres


-------------------------------------------------------------
Les scripts sont illustrés par 3 exemples de complexité croissante:

Exemple 1 : assignation de sujets (préexistants) + envoi par mail + aide à la correction

Exemple 2 : idem + génération de sujets individualisés (basé sur des versions de chaque exercice)

Exemple 3 : idem + génération de sujets individualisés avec génération aléatoire de paramètres (avec python)

-------------------------------------------------------------
Exécutables requis:

Pour tous les scripts:
- ruby (avec quelques "gem" requis -- a priori plutôt standard)
- unoconv (version ligne de commande de libreoffice)

Pour la génération basique de sujets avec versions:
- pdflatex (avec quelques package latex requis -- a priori plutôt standard)

Pour la génération aléatoire de paramètres numériques:  
- python (avec le module numpy)

Pour l'aide à la correction: 
- un navigateur de fichier, lecteur de photos, lecteur de pdf, etc.
- wmctrl (manipulation des fenêtres x11 en ligne de commande) -- optionnel

-------------------------------------------------------------
Adrien Wohrer 2020, IUT Clermont-Ferrand, Département Info, équipe de maths
