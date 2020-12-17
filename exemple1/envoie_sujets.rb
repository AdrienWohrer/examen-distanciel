#!/usr/bin/ruby
# -*- coding: utf-8 -*-


# Envoi individuel des sujets d'interro + consignes

# Lancement : 
# ruby envoie_sujets.rb

# Exécutables nécessaires à installer :
# * unoconv : version 'ligne de commande' de libreoffice.

# Problèmes connus :
# * Classe ou gem ruby manquant : installer le gem correspondant 
#       --> exemple pour installer le gem 'highline' : sudo gem install highline
# * Erreur de unoconv : "Error: Unable to connect or start own listener. Aborting." 
#       --> Survient parfois si un fichier .ods est déjà ouvert. Simplement relancer le script.


# Classes et gems ruby nécessaires
#####################################

# pour installer un gem manquant, par exemple le gem 'highline' :
# sudo gem install highline

require 'rubygems'
require 'highline/import'
require 'net/smtp'
require 'mail'      # gère tous types de serveurs d'envoi et permet de joindre facilement des fichiers (contrairement à net/smtp où j'ai eu des problèmes). 
# https://www.rubydoc.info/github/mikel/mail


# Configuration
#####################################

FileEtud = "assignation.ods" 
SujetDir = "Sujets"                 # emplacement des sujets
NomEnvoi = "Examen.pdf"             # nom générique de la pièce jointe à envoyer

ReallySend = false                  # passer à true pour vraiment procéder à l'envoi

### Paramètres du mail
Who='Adrien Wohrer'
From='adrien.wohrer@uca.fr'
MTA='smtp.uca.fr'
Subject="Math -- Examen"

InteractivePwd = true
#   true  ->  demande le MDP de la boîte mail lors l'exécution. Plus sécure. Nécessite le gem highline.
#  false  ->  entrer le MDP de la boîte mail en dur, en argument de l'appel. Moins sécure. Ne nécessite pas le gem highline.
#             - usage basique dans ce cas :     ruby envoie_sujets.rb monmotdepasse
#             - permet aussi le scheduling :    echo "ruby envoie_sujets.rb monmotdepasse" | at 13h25

require 'highline/import' if InteractivePwd


# Demande de mot de passe pour le serveur mail (fonction)
#####################################
    
$mail_initialized = false
def initMail
    if not $mail_initialized
        # récupération du mot de passe
        pwd = InteractivePwd ? 
            ask("Enter your password for connection to the smtp server:  ") { |q| q.echo = "*" } : 
            ARGV[0]
        
        # https://medium.com/derek-gc/sending-emails-in-ruby-with-smtp-3d40bed6c437
        Mail.defaults do
            delivery_method :smtp, address: MTA, port: 587, password: pwd, authentication: :login, user_name: From
        end
       
        $mail_initialized = true
    end
end


# Contenu du mail (fonction)
#####################################

def sendMail(adresse,nom,prenom,sujet_pdf)

    corps = <<EOF

Bonjour #{prenom} #{nom},

Voici votre sujet individualisé pour l'examen de mathématiques

********************************

* La durée du contrôle est de 1h (+ 15 minutes de délai technique)

* Vous devez répondre aux questions en écrivant à la main sur une copie en papier

* Vous devez rendre votre copie sous forme d'un ou plusieurs fichiers : photo ou scan (jpg, png, pdf)

* Vous devez avoir rendu votre copie avant 14h45 en la déposant sur moodle, dans l'onglet "semaine 3" du cours d'algèbre linéaire

**************************

* Calculatrices, Sage, documents, etc. autorisés

* Attention à donner un maximum de détails de calcul et de rédaction

**************************

* Les profs tiendront une permanence rocket sur le canal iutinfo1atousmaths à partir de 13h15

*************************

Cordialement,
L'équipe enseignante de mathématiques

EOF

    # Commande d'envoi simplifiée avec le gem Mail
    
    if ReallySend
        initMail
        Mail.deliver do
            #charset='UTF-8' # marche pas ? bref... :(
            from    From
            to      adresse
            subject Subject
          
            text_part do
                body corps
            end
          
            add_file :filename => NomEnvoi, :content => File.read(sujet_pdf)
        end
    else
        # simple affichage
        puts From
        puts adresse
        puts Subject
        puts corps
    end
end


# Lecture du fichier étudiant et envoi des mails
#####################################

### Conversion automatique du fichier ODS (ou XLS) en un fichier CSV
# Options du filtre: voir
#     https://wiki.openoffice.org/wiki/Documentation/DevGuide/Spreadsheets/Filter_Options

ods2csv_command = "unoconv -f csv -e FilterOptions=58,34,76,3,,2060,true,true"

ext = File.extname(FileEtud)
if  ext != ".ods" and ext != ".xls"
  puts "ERROR. Wrong file format. Only .ods or .xls accepted"
  exit(1)
end
csvfile = ".#{File.basename(FileEtud, ext)}.csv"
if not system(ods2csv_command+" -o #{csvfile} #{FileEtud}")
  warn "Unoconv conversion error (arrive souvent, relancer simplement le script)"
  exit(1)
end


### Lecture des lignes du CSV et envoi

IO.readlines(csvfile).each_with_index { |l, id|	
    begin   # (permet de récupérer la ligne d'un éventuel problème)
    
        data = l.chomp.split(":");              # chomp vire le \n final
        # 5 premières colonnes (toujours les mêmes)
        grnum = Integer(data.shift()) rescue nil
        next unless grnum && grnum >= 0      # Continue uniquement pour les "vraies" lignes, caractérisées par un "vrai" numéro de groupe en 1ère colonne (entir poitif).
        nom = data.shift().tr('"', '')
        prenom = data.shift().tr('"', '')
        adresse = data.shift().tr('"', '')
        pdfname = data.shift().tr('"', '')
    
        sujet_pdf = "#{SujetDir}/#{pdfname}.pdf"
        puts "Envoi à #{nom} #{prenom}"
        sendMail(adresse, nom, prenom, sujet_pdf)
    
    rescue Exception => e
        puts "ERREUR, pendant le traitement de la ligne #{id+1}, du fichier de notes #{csvfile} :"
        puts e.message
        print "\n"+e.backtrace.join("\n")+"\n"
        exit(1)
    end
}

puts "Passer ReallySend à true pour vraiment procéder à l'envoi" unless ReallySend



