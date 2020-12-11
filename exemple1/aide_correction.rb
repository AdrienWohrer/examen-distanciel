#!/usr/bin/ruby
# -*- coding: utf-8 -*-


# Aide à la correction 
# * ouvre chaque rendu étudiant et la correction associée
# * Taper entrée dans la console pour passer à l'étudiant suivant
# * Les fenêtres de l'étudiant précédent sont alors fermées automatiquement

# Lancement : 
# ruby aide_correction.rb           [démarre au premier étudiant]
# ruby aide_correction.rb Dupont    [commence à partir de l'étudiant Dupont]

# Attention, le script ne décompresse pas tout seul les archives.
# Pour ce faire, le plus simple est d'exécuter
# Exécutables nécessaires à installer :
# * unoconv : version 'ligne de commande' de libreoffice.
# * wmctrl : gestion en ligne de commande des fenêtres graphiques [optionnel]
# * un éditeur de texte, un visionneur de pdf, etc. (cf configuration, ci-dessous)

# Problèmes connus :
# * Classe ou gem ruby manquant : installer le gem correspondant 
#       --> exemple pour installer le gem 'highline' : sudo gem install highline
# * Erreur de unoconv : "Error: Unable to connect or start own listener. Aborting." 
#       --> Survient si le fichier .ods avec la liste des étudiants est déjà ouvert. Juste relancer le script.
# * Le script ne décompresse pas automatiquement les archives
#       --> décompresser 'à la main' le .zip de l'étudiant, faire 'étudiant précédent' [p+Entrée] puis 'étudiant suivant' [Entrée] pour recharger le rendu (maintenant décompressé) de l'étudiant


# TODO
# mieux gérer les spawn, créer des group process afin d'accéder aux fenêtres directement à partir des PID, etc.
# https://ruby-doc.org/core-2.6.1/Process.html


# Configuration
#####################################

$file = "assignation.ods"       # liste des étudiants
$correcdir = "Corrigés"         # emplacement des corrigés
$rendudir = "RENDUS"            # emplacement des rendus des étudiants

# Quels groupes désire-t'on corriger ?
$groupes = [1,2]

# éxécutables linux à utiliser. Ici, ceux par défaut de la distribution Debian. À adapter dans le cas d'autres distributions (genre KDE)
$pdfviewer = 'evince'
$imageviewer = 'eog'            # 'eye of gnome'
$filenavigator = 'nautilus'     # navigateur de fichiers
$texteditor = 'gedit'           # éditeur de texte
$office = 'libreoffice'         # odt, docx, etc.

# Position souhaitée pour les deux types de fenêtres (corrigé, rendus étudiants)
# Nécessite wmctrl (sous linux)
$pos_corrige = "900,290,1000,850"      # "xupperleft,yupperleft,w,h"
$pos_rendu = "0,20,800,1060"           # "xupperleft,yupperleft,w,h"


# Classes et gems ruby nécessaires
#####################################

# pour installer un gem manquant, par exemple le gem 'highline' :
# sudo gem install highline

require 'rubygems'
require 'fileutils'
require 'timeout'
require 'find'


# Lecture et stockage des noms/prénoms
######################################

# Conversion automatique du fichier ODS (ou XLS) en un fichier (caché) CSV
# nécesite d'avoir installé unoconv
# Options du filtre: voir
#     https://wiki.openoffice.org/wiki/Documentation/DevGuide/Spreadsheets/Filter_Options

ods2csv_command = "unoconv -f csv -e FilterOptions=58,34,76,3,,2060,true,true"

ext = File.extname($file)
if  ext != ".ods" and ext != ".xls"
  puts "ERROR. Wrong file format. Only .ods or .xls accepted"
  exit(1)
end
csvfile = ".#{File.basename($file, ext)}.csv"
if not system(ods2csv_command+" -o #{csvfile} #{$file}")
  warn "Unoconv conversion error (arrive souvent, relancer simplement le script)"
  exit(1)
end

etudiants = Array.new

IO.readlines(csvfile).each do |l|
    data = l.chomp.split(":");              # chomp vire le \n final
    # 5 premières colonnes (toujours les mêmes)
    grnum = Integer(data.shift()) rescue nil
    next unless grnum && grnum >= 0      # Continue uniquement pour les "vraies" lignes, caractérisées par un "vrai" numéro de groupe en 1ère colonne (entir poitif).
    nom = data.shift().tr('"', '')
    prenom = data.shift().tr('"', '')
    adresse = data.shift().tr('"', '')
    filename = data.shift().tr('"', '')
  
    etudiants.push({:nom=>nom, :prenom=>prenom, :fichier=>filename}) if $groupes.include?(grnum) 
end

if etudiants.empty?
    warn "Liste d'étudiants vide (peut-être un mauvais numéro de groupe?)"
    exit(1)
end
puts etudiants



# Fonctions principales : ouverture de fichiers/répertoires, gestion des fenêtres, etc.
#######################################################################################


# Vérifie si wmctrl est installé sur le système
$wmctrl = `which wmctrl`.delete!("\n")
$is_wmctrl = $?.success?
if not $is_wmctrl
    puts "WARNING !!! wmctrl n'est pas installé, on ne pourra pas dimensionner, ni fermer automatiquement les fenêtres"
    sleep(3)
end


# Fonction utilitaire: Array des identifiants x11 des fenêtres actuellement ouvertes

def current_windows
    if $is_wmctrl 
        `#{$wmctrl} -l`.split("\n").map{ |widline| widline.split(" ")[0]  }     # identifiant de la fenêtre = code hexa avant le premier espace
    else
        []
    end
end


# Fonction utilitaire: ferme une (ou des) fenêtre(s), identifiée par son identifiant x11

def close_window(wid)
    if wid.respond_to?(:each)              # close Array of windows
        wid.each{ |w| close_window(w) }
    else                                    # close single window
        `#{$wmctrl} -i -c #{wid}` if $is_wmctrl and not wid.nil?
    end
end


# Fonction utilitaire:
# - lance un processus détaché (spawn)
# - renvoie un Array des identifiants x11 de(s) fenêtre(s) créée(s) [fiable uniquement pour la première créée]

def my_spawn(command)
    windowsbefore = current_windows
    sleep(0.1)
    Process.detach spawn(command)
    newwindows = []
    if $is_wmctrl
        begin
            Timeout::timeout(4) do
                while newwindows.empty? do      # pour attendre que la fenêtre soit créée
                    newwindows = current_windows - windowsbefore
                    sleep(0.1)
                end
            end
        rescue Timeout::Error
            puts "WARNING: nouvelle(s) fenêtre(s) associées à la commande #{command} non trouvées; ne pourront pas être positionnées, ni fermées automatiquement."
        end
    end
    newwindows
end
    

# Fonction utilitaire:
# - ouvre un fichier (suivant son extension) ou un répertoire
# - en option, redimensionne la fenêtre: pos = "xupperleft,yupperleft,w,h" (string)
# - renvoie les identifiants de fenêtre (avec wmctrl) sous forme d'un Array

def ouvre_dans_fenetre(path, pos=nil)
    if File.directory?(path)
        command = "#{$filenavigator} \"#{path}\""
    else
        ext = File.extname(path).downcase
        case ext
        when ".jpg", ".jpeg", ".png", ".bmp"
            command = "#{$imageviewer} \"#{path}\""
        when ".pdf"
            command = "#{$pdfviewer} \"#{path}\""
        when ".txt"
            command = "#{$texteditor} \"#{path}\""
        when ".odt", ".docx"
            command = "#{$office} \"#{path}\""
        else
            puts "WARNING: unknown file format : #{ext}"
            puts path
            return []
        end
    end
    wids = my_spawn(command)
    #puts "#{path} : #{wids}"
    
    # repositionne, si demandé
    wids.map do |wid|
        `#{$wmctrl} -i -r #{wid} -b remove,maximized_vert -b remove,maximized_horz`
        `#{$wmctrl} -i -r #{wid} -e 0,#{pos}`  # -e 0,x(upleft),y(upleft),w,h
    end unless pos.nil?
    
    wids
end
                

# Fonction principale pour un étudiant

def ouvre_etudiant(h)
    nom = h[:nom]
    prenom = h[:prenom]
    filename = h[:fichier]
    
    puts "OUVERTURE du dossier : #{nom}, #{prenom}"
    
    # Ouvre le corrigé + essaye de dimensionner la fenêtre
    wids_corrige = ouvre_dans_fenetre("#{$correcdir}/#{filename}.pdf", $pos_corrige)
    
    # Ouvre le dossier de rendu étudiant. Doit nécessairement commencer par "NOM Prénom..."
    rendu_etud = Dir.glob("#{$rendudir}/#{nom} #{prenom}*")
    wids_rendu = Array.new
    
    if rendu_etud.empty?
        puts "WARNING: AUCUN RENDU trouvé à l'emplacement suivant: #{$rendudir}/#{nom} #{prenom}*"
    
    elsif rendu_etud.size > 1
        puts "\nERREUR: PLUSIEURS RÉPERTOIRES associés au nom de l'étudiant:"
        puts rendu_etud
        puts "Merci de fusionner de tous les répertoires de rendu avant de reprendre la correction !"
        exit 1
        
    else
        rendu_etud = rendu_etud[0]
        # fenetre avec le répertoire (peut aider en cas de pb)
        wids_rendu += ouvre_dans_fenetre(rendu_etud, $pos_rendu)
        
        # Parcourt le dossier de rendu étudiant et ouvre tous les pdf/images
        #       (reverse_each pour respecter l'ordre logique d'empilement des pdf 1,2,3...)
        Find.find(rendu_etud).reverse_each do |path|
            if FileTest.directory?(path)   
                # fenêtre unique pour toutes les IMAGES éventuellement présentes dans ce répertoire
                yo = Dir.glob("#{path}/*.{jpg,jpeg,png,bmp,JPG,JPEG,PNG,BMP}")
                wids_rendu += ouvre_dans_fenetre(yo[0], $pos_rendu) unless yo.empty?
            else
                # une fenêtre individuelle pour chaque fichier de type pdf et texte
                case File.extname(path).downcase
                when ".jpg", ".jpeg", ".png", ".bmp"    # déjà traité au niveau du répertoire
                else
                    wids_rendu += ouvre_dans_fenetre(path, $pos_rendu)
                end
            end
        end
    end
    
    [wids_corrige, wids_rendu]
end

# test
#puts ouvre_etudiant(etudiants[5])
#exit


# Boucle préliminaire : décompression d'éventuelles archives
#############################################################


# extensions associées à des archives (à compléter si j'en oublie)
archiveext = "zip,tar,rar,gz,xz,7z,bz2,zipx,zz"

dirs_with_archive = Find.find(".").select do |path|
    FileTest.directory?(path) and Dir.glob("#{path}/*.{#{archiveext}}").size > 0
end

unless dirs_with_archive.empty?
    puts "Des fichiers d'archive ont été repérés. Chaque répertoire contenant une archive va être ouvert."
    puts "Décompressez à la main chaque archive rencontrée, puis détruisez le fichier d'archive (afin d'éviter cette étape la prochaine fois)."
    puts "Appuyez sur entrée pour passer au répertoire suivant."
    STDIN.gets.chomp
end

dirs_with_archive.each do |path|
    wid = ouvre_dans_fenetre(path)
    puts "Décompressez du contenu si nécessaire, puis tapez entrée pour répertoire suivant"
    STDIN.gets.chomp
    close_window(wid)
end

        
# Boucle pour parcourir les étudiants
##########################################################

# par défaut commence au début
currid = 0

if ARGV.size > 0 
    # cherche le point de départ si un nom a été renseigné
    yo = etudiants.each_with_index.select { |h,i| h[:nom].match(/#{ARGV[0]}/i) }
    if yo.length>0
        currid = yo[0][1] 
    else
        puts "Nom requis non trouvé dans la liste. JE COMMENCE AU DÉBUT."
    end
end

while true
    wids_corrige, wids_rendu = ouvre_etudiant(etudiants[currid])
    puts "ETUDIANT SUIVANT [entrée] / PRÉCÉDENT [p puis entrée] ?" 
    reply = STDIN.gets.chomp
    puts reply

    # tue les vieilles fenêtres
    allwids = wids_rendu + wids_corrige
    10.times do
        allwids.each { |wid| close_window(wid) }
        sleep(0.1)
    end
    
    # nouvel étudiant
    if reply[0] == 'p'
        currid -= 1
    else
        currid += 1
    end
    
    exit 0 if currid == etudiants.size
end




