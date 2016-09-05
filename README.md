# dp

Zdrojaky, jak jsou na dvd k diplomce + Vagrantfile pro vytvoreni VM.

## Prerekvizity

 - [VirtualBox](https://www.virtualbox.org/)
 - [Vagrant](https://www.vagrantup.com/)
 - `srilm.tar.gz` (ziskate z http://www.speech.sri.com/projects/srilm/download.html)
 - adresar s ukazkovymi daty z dvd (`src/system/data/poc/`)
 
## vm

 - nakopirovat `srilm.tar.gz` do adresare `projects`
 - nakopirovat adresar `poc` do adresare `projects`
 - `vagrant up` stahne obraz ubuntu, nastavi podle definic v souboru `Vagrantfile`, pro inicializaci pouzije skript [projects/bootstrap.sh](projects/bootstrap.sh). Skript nainstaluje a zkompiluje potrebne knihovny a na zaver pusti analyzator na soubor `2014-03-10-200004-CT_24-HYDEPARK.wav` v adresari poc. Vysledky ulozi v adresari /tmp/output.
 - ke stroji se lze prihlasit pomoci `vagrant ssh`
