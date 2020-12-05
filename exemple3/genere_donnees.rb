#!/usr/bin/ruby
# -*- coding: utf-8 -*-

# Génération individuelle des données de l'examen, via l'appel au script python "generation_donnees.py"

# Lancement : 
# ruby genere_donnees.rb

# Exécutables nécessaires à installer :
# * unoconv : version 'ligne de commande' de libreoffice.
# * python (ou tout autre langage que l'utilisateur décide d'utiliser pour générer des données aléatoires -- par exemple matlab)

# Problèmes connus :
# * Classe ou gem ruby manquant : installer le gem correspondant 
#       --> exemple pour installer le gem 'highline' : sudo gem install highline
# * Erreur de unoconv : "Error: Unable to connect or start own listener. Aborting." 
#       --> Survient parfois si un fichier .ods est déjà ouvert. Simplement relancer le script.


# Classes et gems ruby nécessaires
#####################################

# pour installer un gem manquant, par exemple le gem 'machin' :
# sudo gem install machin

require 'rubygems'
require 'fileutils'

# Configuration
#####################################

$file = "assignation.ods"           # format ods (ou xls)
$donneesdir = "Données_indiv"       # répertoire destination des données individuelles
$pythonscript = "random_params.py"  # script de génération aléatoire des données

######################################################
######################################################



## Conversion automatique du fichier ODS (ou XLS) en un fichier (caché) CSV
######################################

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


puts "Récupère les noms des étudiants dans le tableur"

alltexs = Array.new

IO.readlines(csvfile).each do |l|	
    data = l.chomp.split(":");              # chomp vire le \n final
    # 5 premières colonnes (toujours les mêmes)
    grnum = Integer(data.shift()) rescue nil
    next unless grnum && grnum >= 0      # Continue uniquement pour les "vraies" lignes, caractérisées par un "vrai" numéro de groupe en 1ère colonne (entir poitif).
    nom = data.shift().tr('"', '')
    prenom = data.shift().tr('"', '')
    adresse = data.shift().tr('"', '')
    filename = data.shift().tr('"', '')
    # Colonnes restantes -> assignedparameters
    assignedparameters=data.map{|d| d.tr('"', '')}.join(",")
        
    alltexs.push "\"#{$donneesdir}/#{filename}.tex\"" # fichier tex de paramétrisation pour cet étudiant
end

puts "Génération des données individualisées avec Python"

FileUtils.mkdir "#{$donneesdir}" if not Dir.exists? "#{$donneesdir}"

python_command = "python #{$pythonscript} #{alltexs.join(" ")}"
puts python_command

if not system(python_command)
    warn "PYTHON ERROR (#{$pythonscript})"
    exit(1)
end

puts "Done!"

