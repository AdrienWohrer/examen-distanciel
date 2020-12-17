#!/usr/bin/ruby
# -*- coding: utf-8 -*-

# Génération individuelle des sujets avec pdflatex

# Lancement : 
# ruby genere_sujets.rb

# Exécutables nécessaires à installer :
# * unoconv : version 'ligne de commande' de libreoffice.

# Problèmes connus :
# * Classe ou gem ruby manquant : installer le gem correspondant 
#       --> exemple pour installer le gem 'highline' : sudo gem install highline
# * Erreur de unoconv : "Error: Unable to connect or start own listener. Aborting." 
#       --> Survient parfois si un fichier .ods est déjà ouvert. Simplement relancer le script.


# Classes et gems ruby nécessaires
#####################################

# pour installer un gem manquant, par exemple le gem 'machin' :
# sudo gem install machin

require 'fileutils'

# Configuration
#####################################

$file = "assignation.ods"       # format ods (ou xls)
$source = "Examen.tex"
$donneesdir = "Données_indiv"   # source des fichiers de données latex individuels
$sujetdir = "Sujets"            # destination des sujets
$correcdir = "Corrigés"         # destination des corrigés
$builddir = "build"             # destination des fichiers auxiliaires

#$a_generer = [:sujet]
#$a_generer = [:corrige]
$a_generer = [:sujet, :corrige]


# Conversion automatique du fichier ODS (ou XLS) en un fichier (caché) CSV
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

# Génération des sujets
######################################

puts "Génération des sujets avec PDFLATEX"

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
    
    # Emplacement du fichier de données individuelles
    texperso="#{$donneesdir}/#{filename}.tex"
    
    $a_generer.each do |sujcorr|

        case sujcorr
            when :sujet
                pdfdir = $sujetdir
                iscorrec = 0
            when :corrige
                pdfdir = $correcdir
                iscorrec = 1
        end
        
        FileUtils.mkdir "#{pdfdir}" if not Dir.exists? "#{pdfdir}"
        FileUtils.mkdir "#{$builddir}" if not Dir.exists? "#{$builddir}"
        
        pdflatex_command = "pdflatex -jobname=\"#{filename}\" -output-directory #{$builddir} \"\\def\\iscorrec{#{iscorrec}} \\def\\texperso{\\\"#{texperso}\\\"} \\def\\assignedparameters{#{assignedparameters}} \\input{#{$source}}\""
        
        if not system(pdflatex_command)
            warn "pdflatex error"
            exit(1)
        end
        FileUtils.mv("#{$builddir}/#{filename}.pdf",pdfdir)
        FileUtils.rm_r "#{$builddir}"
  end

end


