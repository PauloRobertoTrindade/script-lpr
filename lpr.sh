#!/usr/bin/env bash

#########################################################################################
#                                                                                       #
# lpr.sh - Scrip de instalacao ou atualizacao do servico de LPR.                        #
#                                                                                       #
# Versao atual: 1.5.2                                                                   #
#                                                                                       #
# Autor: Paulo Trindade (paulo.filho@wps-sa.com.br)                                     #
# Data Criacao: 14/12/2024                                                              #
#                                                                                       #
# Descricao: Scrip que instala ou atualiza o servico de LPR.                            #
#                                                                                       #
# Exemplo de uso: ./lpr.sh                                                              #
#########################################################################################

#Comando que faz com o que as teclas Backspace e Delete funcione com o comando read
stty erase ^H
stty erase ^?

#######################################################################
############################## VARIAVEIS ##############################
#######################################################################

#Caminho do arquivo para atualizar repositorio CentOS 7
CONFIG_FILE="/etc/yum.repos.d/CentOS-Base.repo"

#CORES
ROSA="\033[35m"
CINZA_CLARO="\033[00;37m"
VERDE="\033[32m"
AMARELO="\033[33m"
VERMELHO="\033[31m"

#####################################################################
############################## FUNCOES ##############################
#####################################################################

VerificaInternet () {
#Funcao que verifica se o servidor tem conexao com a internet e caso nao tenha, da a opcao de configuracao
    
    echo -e "$AMARELO--------------------------------$CINZA_CLARO"
    echo -e "$AMARELO----- VERIFICANDO INTERNET -----$CINZA_CLARO"
    echo -e "$AMARELO--------------------------------$CINZA_CLARO"
    echo

    #ping -w1 www.google.com.br > /dev/null 2>&1
    if [ $SO = "deb" ]
    then
        ping -c 1 -W 1 www.google.com.br > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
            while true
            do
                read -p "Sem acesso a internet, gostaria de configurar o arquivo de rede? (Ex.: 1 - sim | 2 - nao): " configuracao_rede
                case "$configuracao_rede" in
                    1)
                        echo
                        cd /etc/netplan
                        echo "Seguindo para as opcoes, ALTERANDO as configuracoes de rede!"
                        echo
                        echo "Selecione o numero, referente a qual arquivo sera editado (Ex.: 1): "
                        arquivos_rede=$(ls -1 /etc/netplan/)
                        select arquivo in $arquivos_rede
                        do
                            if [ -n "$arquivo" ] && [ -f "$arquivo" ]
                            then
                                #Verifica se o arquivo tem o nome wi-fi - nao configuramos a placa de rede wi-fi
                                if [[ "$arquivo" == *"wi-fi"* || "$arquivo" == *"wifi"* ]]
                                then
                                    echo "O arquivo escolhido nao pode ter o nome 'wi-fi'. Escolha outro arquivo."
                                else
                                    echo "Voce escolheu editar o arquivo: "$VERDE"$arquivo"$CINZA_CLARO""

                                    #Criando nome do arquivo de backup de configuracao de rede
                                    backup_nome="backup_$arquivo"
                                    contador=1

                                    #Verificando se ja existe backup do arquivo, caso exista adiciona um numero
                                    while [ -e "$backup_nome" ]
                                    do
                                        backup_nome="backup_$arquivo_${contador}"
                                        contador=$((contador + 1))
                                    done

                                    #Criando backup do arquivo de configuracao de rede
                                    cp "$arquivo" "$backup_nome"
                                    
                                    #Verificacao de configuracao: IP Estatico ou DHCP
                                    echo -e "$VERDE--------------------"
                                    echo -e "$VERDE| $CINZA_CLARO 1 - IP ESTaTICO $VERDE|"
                                    echo -e "$VERDE--------------------"
                                    echo -e "$VERDE| $CINZA_CLARO 2 - $VERMELHO DHCP $VERDE      |"
                                    echo -e "$VERDE--------------------$CINZA_CLARO"
                                    read -p "Qual o tipo de configuracao da placa de rede (1 - IP Estatico | 2 - DHCP)? " conf_placa_rede

                                    #Configuracao da placa de rede
                                    case "$conf_placa_rede" in
                                        1)
                                            #IP Estatico
                                            read -p "DIGITE QUAL O NOME DA PLACA DE REDE (Ex.: enp3s0)? " nome_placarede
                                            read -p "DIGITE QUAL SERA O IP DO SERVIDOR LPR (Ex.: 125.125.10.150)? " ip_servidor
                                            read -p "DIGITE QUAL SERA O GATEWAY DO SERVIDOR LPR (Ex.: 125.125.10.1)? " ip_gateway
                                            read -p "DIGITE QUAL SERA A MASCARA DO SERVIDOR LPR (Ex.: 24, 22, 16 - 24 equivale a 255.255.255.0)? " mascara
                                            read -p "DIGITE QUAL SERA O IP DNS 1 DO SERVIDOR LPR (Ex.: 8.8.8.8)? " ip_dns1
                                            read -p "DIGITE QUAL SERA O IP DNS 2 DO SERVIDOR LPR (Ex.: 8.8.4.4)? " ip_dns2

                                            echo -e "network:\n  version: 2\n  renderer: networkd\n  ethernets:\n    $nome_placarede:\n      addresses:\n       - $ip_servidor/$mascara\n      routes:\n       - to: default\n         via: $ip_gateway\n      nameservers:\n         addresses: [$ip_dns1, $ip_dns2]" > "$arquivo"
                                            ;;
                                        2)
                                            #DHCP
                                            read -p "DIGITE QUAL O NOME DA PLACA DE REDE (Ex.: enp3s0)? " nome_placarede
                                            echo -e "network:\n  version: 2\n  renderer: networkd\n  ethernets:\n    $nome_placarede:\n      dhcp4: true" > "$arquivo"
                                            ;;
                                        *)
                                            echo "Opcao invalida. Digite 1 para IP Estatico ou 2 para DHCP."
                                            ;;
                                    esac

                                    #Pergunta se deseja adicionar mais uma interface
                                    echo
                                    echo -e "$VERDE-----------------"
                                    echo -e "$VERDE| $CINZA_CLARO 1 - SIM $VERDE       |"
                                    echo -e "$VERDE-----------------"
                                    echo -e "$VERDE| $CINZA_CLARO 2 - $VERMELHO NaO, SAIR $VERDE |"
                                    echo -e "$VERDE-----------------$CINZA_CLARO"
                                    read -p "Gostaria de adicionar uma nova placa de rede? (Ex.: 1)? " add_nova_placa_rede
                                    while [ $add_nova_placa_rede -eq 1 ]
                                    do
                                        echo -e "$VERDE-------------------------"
                                        echo -e "$VERDE| $CINZA_CLARO 1 - IP ESTaTICO $VERDE       |"
                                        echo -e "$VERDE-------------------------"
                                        echo -e "$VERDE| $CINZA_CLARO 2 - $VERMELHO DHCP $VERDE      |"
                                        echo -e "$VERDE-------------------------$CINZA_CLARO"
                                        read -p "Qual o tipo de configuracao da placa de rede (1 - IP Estatico | 2 - DHCP)? " conf_nova_placa_rede

                                        case "$conf_nova_placa_rede" in
                                            1)
                                                #IP Estatico
                                                read -p "DIGITE QUAL O NOME DA PLACA DE REDE (Ex.: enp3s0)? " nome_placarede
                                                read -p "DIGITE QUAL SERA O IP DO SERVIDOR LPR (Ex.: 125.125.10.150)? " ip_servidor
                                                read -p "DIGITE QUAL SERA O GATEWAY DO SERVIDOR LPR (Ex.: 125.125.10.1)? " ip_gateway
                                                read -p "DIGITE QUAL SERA A MASCARA DO SERVIDOR LPR (Ex.: 24, 22, 16 - 24 equivale a 255.255.255.0)? " mascara
                                                read -p "DIGITE QUAL SERA O IP DNS 1 DO SERVIDOR LPR (Ex.: 8.8.8.8)? " ip_dns1
                                                read -p "DIGITE QUAL SERA O IP DNS 2 DO SERVIDOR LPR (Ex.: 8.8.4.4)? " ip_dns2

                                                echo -e "\n    $nome_placarede:\n      addresses:\n       - $ip_servidor/$mascara\n      routes:\n       - to: default\n         via: $ip_gateway\n      nameservers:\n         addresses: [$ip_dns1, $ip_dns2]" >> "$arquivo"

                                                echo
                                                echo -e "$VERDE-----------------"
                                                echo -e "$VERDE| $CINZA_CLARO 1 - SIM $VERDE       |"
                                                echo -e "$VERDE-----------------"
                                                echo -e "$VERDE| $CINZA_CLARO 2 - $VERMELHO NaO, SAIR $VERDE |"
                                                echo -e "$VERDE-----------------$CINZA_CLARO"
                                                read -p "Gostaria de adicionar uma nova placa de rede? (Ex.: 1)? " add_nova_placa_rede
                                                ;;
                                            2)
                                                #DHCP
                                                read -p "DIGITE QUAL O NOME DA PLACA DE REDE (Ex.: enp3s0)? " nome_placarede
                                                echo -e "\n    $nome_placarede:\n      dhcp4: true" >> "$arquivo"

                                                echo
                                                echo -e "$VERDE-----------------"
                                                echo -e "$VERDE| $CINZA_CLARO 1 - SIM $VERDE       |"
                                                echo -e "$VERDE-----------------"
                                                echo -e "$VERDE| $CINZA_CLARO 2 - $VERMELHO NaO, SAIR $VERDE |"
                                                echo -e "$VERDE-----------------$CINZA_CLARO"
                                                read -p "Gostaria de adicionar uma nova placa de rede? (Ex.: 1)? " add_nova_placa_rede
                                                ;;
                                            *)
                                                echo "Opcao invalida. Digite 1 para IP Estatico ou 2 para DHCP."
                                                ;;
                                        esac
                                    done
                                    sudo netplan apply
                                    break
                                fi
                            else
                                echo "Opcao invalida. Por favor, escolha um arquivo valido."
                            fi
                        done
                        cd ~
                        ;;
                    2)
                        echo "Seguindo para as opcoes sem alterar as configuracoes de rede!"
                        break
                        ;;
                    *)
                        echo "Opcao invalida. Digite 1 para SIM ou 2 para NaO."
                        ;;
                esac
            done
        else
            ping -c 1 -W 1 www.google.com.br > /dev/null 2>&1
        fi
    fi
    if [ $? -eq 0 ]
    then
        echo " - MAQUINA POSSUI CONEXAO COM A INTERNET !!! -"
    fi
}

MenuEscolheAcao () {
#Funcao para escolher o tipo de acao que o scrip ira realizar (Instalacao ou Atualizacao)
    echo -e "$AMARELO-------------------------------------------$CINZA_CLARO"
    echo -e "$AMARELO----- MENU - ESCOLHA A OPCAO DESEJADA -----$CINZA_CLARO"
    echo -e "$AMARELO-------------------------------------------$CINZA_CLARO"
    echo
    echo -e "$VERDE""-----------------------------------------------"
    echo -e "$VERDE""| "$CINZA_CLARO"1 - INSTALACAO"$VERDE"                              |"
    echo -e "$VERDE""-----------------------------------------------"
    echo -e "$VERDE""| "$CINZA_CLARO"2 - ATUALIZACAO - WEB IMAGES E CONCENTRADOR"$VERDE" |"
    echo -e "$VERDE""-----------------------------------------------"
    echo -e "$VERDE""| "$CINZA_CLARO"3 - ATUALIZACAO - ENGINE"$VERDE"                    |"
    echo -e "$VERDE""-----------------------------------------------"
    echo -e "$VERDE""| "$CINZA_CLARO"4 - CONFIGURACAO DE CAMERA (HARPIA)"$VERDE"         |"
    echo -e "$VERDE""-----------------------------------------------"
    echo -e "$VERDE""| "$CINZA_CLARO"5 - "$VERMELHO"SAIR"$VERDE"                                    |"
    echo -e "$VERDE""-----------------------------------------------""$CINZA_CLARO"
    read -p "ESCOLHA A ACAO DESEJADA (Ex.: 1, 2, 3, 4 ou 5): " ESCOLHE_ACAO
    case "$ESCOLHE_ACAO" in
        1)
            echo
            echo -e "Opcao escolhida: "$VERDE"INSTALACAO"$CINZA_CLARO""
            ACAO="INSTALACAO"
            ;;
        2)
            echo
            echo -e "Opcao escolhida: "$VERDE"ATUALIZACAO - WEB IMAGES E CONCENTRADOR"$CINZA_CLARO""
            ACAO="ATUALIZACAO"
            ;;
        3)
            echo
            echo -e "Opcao escolhida: "$VERDE"ATUALIZACAO - ENGINE"$CINZA_CLARO""
            ACAO="ENGINE"
            ;;
        4)
            echo
            echo -e "Opcao escolhida: "$VERDE"CONFIGURACAO DE CAMERA (HARPIA)"$CINZA_CLARO""
            ACAO="CONFIGURACAO_CAMERA"
            ;;
        5)
            echo
            echo "Saindo do Script..."
            sleep 2
            exit 0
            ;;
        *)
            echo
            echo -e " --- Opcao "$VERMELHO"INVALIDA"$CINZA_CLARO", escolha 1, 2, 3 ou 4. ---"
            echo
            MenuEscolheAcao
            return
            ;;
    esac
}

VerificaSO () {
#Funcao que verifica qual o sistema operacional.
    if uname -v |grep Ubuntu > /dev/null
    then
        echo -e "$AMARELO""----------------------------------------------""$CINZA_CLARO"
        echo -e "$AMARELO""----- SISTEMA OPERACIONAL: "$VERDE"UBUNTU (.deb)"$AMARELO" -----""$CINZA_CLARO"
        echo -e "$AMARELO""----------------------------------------------""$CINZA_CLARO"
        echo
        SO="deb"
    else
        echo -e "$AMARELO""----------------------------------------------""$CINZA_CLARO"
        echo -e "$AMARELO""----- SISTEMA OPERACIONAL: "$VERDE"CENTOS (.rpm)"$AMARELO" -----""$CINZA_CLARO"
        echo -e "$AMARELO""----------------------------------------------""$CINZA_CLARO"
        echo
        SO="rpm"
    fi
    sleep 2
}

VerificaVersao () {
#Funcao que verifica se a versao eh um formato valido
#Verifica tambem se os arquivos estao disponiveis para download
    echo
    echo -e "$AMARELO""-------------------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- VALIDA VERSAO NA INTRANET -----""$CINZA_CLARO"
    echo -e "$AMARELO""-------------------------------------""$CINZA_CLARO"
    echo
    versao_regex='^[0-9]\.[0-9]{3}\.[0-9]+$'
    while true; do
        read -p "DIGITE A VERSAO A SER BAIXADA (Ex.: 7.480.3): " VERSAO
        read -p "DIGITE O USUARIO DA INTRANET (Ex.: nome.sobrenome@wps-sa.com.br): " USUARIO
        if [[ "$VERSAO" =~ $versao_regex ]]
        then
            echo -e -n "DIGITE A SENHA DA "$VERDE"INTRANET"$CINZA_CLARO": "
            wget --spider --user=$USUARIO --ask-password --no-check-certificate https://intranet.parkingplus.com.br/pub/Parking%20Plus/ParkingPlus%20-%207/Releases/$VERSAO/ParkingPlusServerServices-$VERSAO/pkplus-cli/LprImagesWebServer/ParkingPlus-LprImagesWebServer-$VERSAO.tgz > /dev/null 2>&1 
            if [ $? -eq 0 ]
            then
                echo
                echo -e "Arquivos encontrados na INTRANET"
                echo
                break       
            else
                echo
                echo -e "Arquivo "$VERMELHO"NAO"$CINZA_CLARO" encontrados na INTRANET, informe outra versao"
                echo
            fi 
        else
            echo
            echo -e "Formato de versao "$VERMELHO"INVALIDO"$CINZA_CLARO", digite conforme exemplo"
            echo
        fi
    done
}

AtualizaRepositorios () {
#Funcao que faz a atualizacao dos repositorios e instalacao de pacotes necessarios de acordo o sistema operacional escolhido
#Primeira opcao Ubuntu e segunda opcao CentOS 7
    echo
    echo -e "$AMARELO""---------------------------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALACAO DE PACOTES NECESSARIOS -----""$CINZA_CLARO"
    echo -e "$AMARELO""---------------------------------------------""$CINZA_CLARO"
    echo
    if [ $SO = "deb" ]
    then
        sudo apt-get update && apt upgrade -y
        apt --fix-broken install
        apt-get install nano wget ntpdate jq net-tools vim mlocate default-jdk iputils-ping pciutils \
        apt-transport-https ca-certificates curl software-properties-common python3 python3.11 python3-pip -y
    else
        sed -i 's/^mirrorlist=/#+mirrorlist=/' "$CONFIG_FILE"
        sed -i '/#baseurl=http:\/\/mirror.centos.org\/centos\/\$releasever\/os\/\$basearch\//a baseurl=http:\/\/vault.centos.org\/centos\/\$releasever\/os\/\$basearch\/' "$CONFIG_FILE"
        sed -i '/#baseurl=http:\/\/mirror.centos.org\/centos\/\$releasever\/updates\/\$basearch\//a baseurl=http:\/\/vault.centos.org\/centos\/\$releasever\/updates\/\$basearch\/' "$CONFIG_FILE"
        sed -i '/#baseurl=http:\/\/mirror.centos.org\/centos\/\$releasever\/extras\/\$basearch\//a baseurl=http:\/\/vault.centos.org\/centos\/\$releasever\/extras\/\$basearch\/' "$CONFIG_FILE"
        sed -i '/#baseurl=http:\/\/mirror.centos.org\/centos\/\$releasever\/centosplus\/\$basearch\//a baseurl=http:\/\/vault.centos.org\/centos\/\$releasever\/centosplus\/\$basearch\/' "$CONFIG_FILE"
        sudo yum clean all
        sudo yum makecache
        sudo yum update -y
        yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm -y
        yum install epel-release -y
        sudo yum update -y
        yum install -y wget nano iputils-ping jq net-tools ntpdate vim mlocate java-1.8.0-openjdk \
            default-jdk pciutils python3 python3-pip python3.11
    fi
}

MostraHora () {
#Funcao que armazena qualquer hora em especifico quando passado um timezone como parametro
    TZ=$1 date +"%H:%M"
}

AtualizaTimezone () {
#Funcao para ajustar o horario do servidor
    echo
    echo -e "$AMARELO""------------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- HORARIO DA MAQUINA -----""$CINZA_CLARO"
    echo -e "$AMARELO""------------------------------""$CINZA_CLARO"
    echo
    while true
    do
        echo -e "$VERDE""----------------------------------"
        echo -e "$VERDE""| "$CINZA_CLARO"1 - $(MostraHora 'America/Sao_Paulo') - America/Sao_Paulo"$VERDE"  |"
        echo -e "$VERDE""----------------------------------"
        echo -e "$VERDE""| "$CINZA_CLARO"2 - $(MostraHora 'America/Manaus') - America/Manaus"$VERDE"     |"
        echo -e "$VERDE""----------------------------------"
        echo -e "$VERDE""| "$CINZA_CLARO"3 - $(MostraHora 'America/Noronha') - America/Noronha"$VERDE"    |"
        echo -e "$VERDE""----------------------------------"
        echo -e "$VERDE""| "$CINZA_CLARO"4 - $(MostraHora 'America/Rio_Branco') - America/Rio_Branco"$VERDE" |"
        echo -e "$VERDE""----------------------------------""$CINZA_CLARO"
        read -p "INFORME QUAL O FUSO HORARIO QUE SERA CONFIGURADO NA MAQUINA (Ex.: 1, 2, 3 ou 4): " timezone
        case "$timezone" in
            1)
                timedatectl set-timezone America/Sao_Paulo
                echo -e "Opcao escolhida foi: "$VERDE"America/Sao_Paulo"$CINZA_CLARO""
                break
                ;;
            2)
                timedatectl set-timezone America/Manaus
                echo -e "Opcao escolhida foi: "$VERDE"America/Manaus"$CINZA_CLARO""
                break
                ;;
            3)
                timedatectl set-timezone America/Noronha
                echo -e "Opcao escolhida foi: "$VERDE"America/Noronha"$CINZA_CLARO""
                break
                ;;
            4)
                timedatectl set-timezone America/Rio_Branco
                echo -e "Opcao escolhida foi: "$VERDE"America/Rio_Branco"$CINZA_CLARO""
                break
                ;;
            *)
                echo
                echo -e " --- Opcao "$VERMELHO"INVALIDA"$CINZA_CLARO", escolha 1, 2, 3 ou 4. ---"
                echo
                AtualizaTimezone
                return
                ;;
        esac
    done
    echo
}

ServPython () {
#Funcao para download de servicos Python
    pip3 install --upgrade pip
    pip install glances gdown py3nvml
}

InstalaDocker () {
#Funcao que realiza download do docker
    echo
    echo -e "$AMARELO""-----------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALANDO DOCKER -----""$CINZA_CLARO"
    echo -e "$AMARELO""-----------------------------""$CINZA_CLARO"
    echo
    curl -fsSL https://get.docker.com/ | sh
}

InstalaDockerCompose () {
#Funcao que realiza download do docker
    echo
    echo -e "$AMARELO""-------------------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALANDO DOCKER COMPOSE -----""$CINZA_CLARO"
    echo -e "$AMARELO""-------------------------------------""$CINZA_CLARO"
    echo
    sudo curl -L https://github.com/docker/compose/releases/download/v2.3.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose -y
    sudo chmod +x /usr/local/bin/docker-compose
}

InstalaPkPlusCli () {
#Funcao que instala o pkplus-cli
    echo
    echo -e "$AMARELO""---------------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALANDO PKPLUS-CLI -----""$CINZA_CLARO"
    echo -e "$AMARELO""---------------------------------""$CINZA_CLARO"
    echo
    if [ $SO = "deb" ]
    then
        echo -e "DIGITE A SENHA DA "$VERDE"INTRANET"$CINZA_CLARO""
        while true 
        do
            wget https://intranet.parkingplus.com.br/pub/Parking%20Plus/pkplus-cli/3.0.0/pkplus-cli_3.0.0-1_all.deb \
            --no-check-certificate --http-user=$USUARIO --ask-password --no-check-certificate
            if [ $? -eq 0 ]
            then
                break
            else
                echo -e ""$VERMELHO"Senha incorreta. Tente novamente."$CINZA_CLARO""
            fi
        done
        apt install ./pkplus-cli_3.0.0-1_all.deb
    else
        pip install --upgrade gdown
        gdown 1Ovka03pyuoAZA_9g75O5sY0MAwap1Ywx
        rpm -ivh pkplus-cli-1.6.4-1.x86_64.rpm
    fi
    mkdir -p /var/lib/pkplus-svc
}

NvidiaContainerToolkit () {
#Funcao que baixa e instala o nvidia-container-tollkit
#Primeira opcao Ubuntu e segunda opcao CentOS 7
    if [ $SO = "deb" ]
    then
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && sudo apt-get update sudo apt-get install -y nvidia-container-toolkit
        systemctl restart docker
    else
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
        sudo yum install -y nvidia-container-toolkit
        systemctl restart docker
    fi
}

VerificaPlacaDeVideo () {
#Funcao que verifica se a maquina tem Placa de Video
    if lspci | grep -i "nvidia" > /dev/null
    then
        echo
        echo -e "$AMARELO""-----------------------------------------""$CINZA_CLARO"
        echo -e "$AMARELO""----- MAQUINA POSSUI PLACA DE VIDEO -----""$CINZA_CLARO"
        echo -e "$AMARELO""-----------------------------------------""$CINZA_CLARO"
        echo
        POSSUI_GPU=1
    else
        echo
        echo -e "$AMARELO""---------------------------------------------""$CINZA_CLARO"
        echo -e "$AMARELO""----- MAQUINA "$VERMELHO"NAO"$AMARELO" POSSUI PLACA DE VIDEO -----""$CINZA_CLARO"
        echo -e "$AMARELO""---------------------------------------------""$CINZA_CLARO"
        echo
        POSSUI_GPU=0
    fi
}

InstalaDriversNvidia () {
#Funcao que realiza a instalacao dos drivers Nvidia - Soh deve ser instalado quando a maquina possuir placa de video
    echo
    echo -e "$AMARELO""------------------------------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALANDO DRIVERS DA PLACA DE VIDEO -----""$CINZA_CLARO"
    echo -e "$AMARELO""------------------------------------------------""$CINZA_CLARO"
    echo
    nvidia-ctk runtime configure --runtime=docker --config=/etc/docker/daemon.json
    systemctl restart docker.service
    if [ $SO = "deb" ]
    then
        sudo apt install nvidia-driver-535 nvidia-dkms-535 -y
    else
        yum -y install nvidia-detect
        yum install -y kmod-nvidia
        yum remove -y xorg-x11-drivers xorg-x11-drv-nouveau
    fi
}

ControleGpu () {
#Funcao que exporta variavel que controla uso de GPU ou nao
    if [ $POSSUI_GPU -eq 1 ]
    then
    #variavel de ambiente para o docker enxergar se existe placa de video instalada na maquina, somente em caso de GPU (PLACA DE VIDEO)
        echo "export NVIDIA_VISIBLE_DEVICES=all" >> ~/.bashrc
    else
    #Exportar variavel de ambiente caso nao haja GPU (PLACA DE VIDEO).
        echo "export NVIDIA_VISIBLE_DEVICES=void" >> ~/.bashrc
    fi
}

NomeMaquina () {
#Funcao que colore e exporta o nome da maquina para corresponder ao nome da garagem
    read -p "DIGITE QUAL SERA O NOME DA MAQUINA (Ex.: WPS_LPR OU LPR_NOME_DA_UNIDADE)? " NM_MAQUINA
    echo "PS1='\[\033[1;31m\]\u\[\033[0;32m\]@"$NM_MAQUINA"\[\e[m\]:\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'" >> ~/.bashrc
    >> ~/.bashrc
    sleep 2
    source ~/.bashrc
}

DesabilitaDobroLog () {
#Funcao que desabilita a duplicacao de logs do journal para o syslog
    echo "if \$programname == 'WpsLprConcentrator' then /dev/null" >> /etc/rsyslog.conf
    sed -i -e 's/^$ModLoad imuxsock/#$ModLoad imuxsock/' -e 's/^$ModLoad imjournal/#$ModLoad imjournal/' /etc/rsyslog.conf
    sed -i -e 's/^module(load="imuxsock")/#module(load="imuxsock")/' -e 's/^module(load="imjournal")/#module(load="imjournal")/' /etc/rsyslog.conf
    systemctl restart rsyslog
}

PerformanceMaquina () {
#Funcao que habilita o modo de performance da maquina
#Primeira opcao Ubuntu e segunda opcao CentOS 7
    if [ $SO = "deb" ]
    then
        gdown 1NxFukxgIMhfG5xfh076dxFkglCtHjO4S
        dpkg -i set-performance_1.0-2_amd64.deb
    else
        gdown 1Roq8tn0COhY-OSrUy_YRNEQuZzdnM4Uu
        rpm -ivh set_performance-1.0-1.x86_64.rpm
    fi
    systemctl start set_performance.service
    systemctl enable set_performance.service
}

ValidaVersaoEngine () {
#Funcao que verifica a versao da engine e se ha a necessidade de baixar o MQTT
    VALIDA_VERSAO_ENGINE=$(echo "$VERSAO_ENGINE" | tr -d '.' | cut -c 1-2)
}

BaixaMqtt () {
#Funcao para baixar o MQTT - soh deve ser habilitada quando a versao da engine for igual ou maior que 2.7.0
    cd /instalacoes/
    echo
    echo -e "$AMARELO""---------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALANDO MQTT -----""$CINZA_CLARO"
    echo -e "$AMARELO""---------------------------""$CINZA_CLARO"
    echo

    curl -X GET \
        -H "Authorization: Bearer "$CHAVE_DOWNLOAD"" \
        -o "/instalacoes/ParkingPlus-MQTT-1.0.0.tgz" \
        "https://storage.googleapis.com/storage/v1/b/lpr-wps-v1/o/ParkingPlus-MQTT-1.0.0.tgz?alt=media"

    sleep 2
    pkplus-cli svc import-file ParkingPlus-MQTT-1.0.0.tgz

    sleep 2
    pkplus-cli svc enable ParkingPlus:MQTT:1.0.0
}

BaixaEngine () {
#Funcao para baixar a ENGINE com ou sem GPU (PLACA DE VIDEO)
    cd /instalacoes/
    echo
    echo -e "$AMARELO""-----------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALANDO ENGINE -----""$CINZA_CLARO"
    echo -e "$AMARELO""-----------------------------""$CINZA_CLARO"
    echo
    
    VERSAO_EN="$VERSAO_ENGINE"
    if [ $POSSUI_GPU -eq 0 ]
    then
        VERSAO_EN="${VERSAO_ENGINE}_cpu"
    fi

    curl -X GET \
        -H "Authorization: Bearer "$CHAVE_DOWNLOAD"" \
        -o "/instalacoes/ParkingPlus-WPSLPR-"$VERSAO_EN".tgz" \
        "https://storage.googleapis.com/storage/v1/b/lpr-wps-v1/o/ParkingPlus-WPSLPR-"$VERSAO_EN".tgz?alt=media"
    if [ $SO = "deb" ]
    then
        sleep 2
        pkplus-cli svc import-file ParkingPlus-WPSLPR-"$VERSAO_EN".tgz
        sleep 2
        pkplus-cli svc enable ParkingPlus:WPS_LPR:"$VERSAO_ENGINE"
    else
        tar -xf ParkingPlus:WPSLPR-x.y.z.tgz
        docker load -i images.tar
        docker-compose up -d
    fi
}

ValidaChave () {
#Funcao que valida se a chave para download da Engine e MQTT eh valida
    echo -e "$AMARELO-------------------------------------------$CINZA_CLARO"
    echo -e "$AMARELO----- VERIFICANDO CHAVE ENGINE / MQTT -----$CINZA_CLARO"
    echo -e "$AMARELO-------------------------------------------$CINZA_CLARO"
    echo
    while true
    do
        resposta=$(curl -s -H "Authorization: Bearer "$CHAVE_DOWNLOAD"" \
                 "https://storage.googleapis.com/storage/v1/b/lpr-wps-v1/o/ParkingPlus-MQTT-1.0.0.tgz?alt=media" -w "%{http_code}" -o /dev/null)
        if [ "$resposta" -eq 200 ]
        then
            echo "Autenticado com sucesso. A chave eh valida."
            break
        else
            read -p "Falha na autenticacao, informe a chave novamente: " CHAVE_DOWNLOAD
        fi
    done
}

InstalaWebImages () {
#Funcao responsavel por instalar / atualizar o Lpr Web Images
    cd /instalacoes/
    echo
    echo -e "$AMARELO""------------------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALACAO DO WEB IMAGES -----""$CINZA_CLARO"
    echo -e "$AMARELO""------------------------------------""$CINZA_CLARO"
    echo
    rm -f /instalacoes/ParkingPlus-LprImagesWebServer-$VERSAO.tgz
    echo -e "DIGITE A SENHA DA "$VERDE"INTRANET"$CINZA_CLARO""
    
    while true
    do
        wget -c -P /instalacoes/ https://intranet.parkingplus.com.br/pub/Parking%20Plus/ParkingPlus%20-%207/Releases/$VERSAO/ParkingPlusServerServices-$VERSAO/pkplus-cli/LprImagesWebServer/ParkingPlus-LprImagesWebServer-$VERSAO.tgz  --user=$USUARIO --ask-password --no-check-certificate
        if [ $? -eq 0 ]
        then
            break
        else
            echo -e ""$VERMELHO"Senha incorreta. Tente novamente."$CINZA_CLARO""
        fi
    done

    sleep 2
    pkplus-cli svc import-file ParkingPlus-LprImagesWebServer-$VERSAO.tgz

    sleep 2
    pkplus-cli svc enable ParkingPlus:LprImagesWebServer:$VERSAO

    if [ $ACAO = "INSTALACAO" ]
    then
        sleep 2
        echo "wpsbrasil:wpsbrasil" > /var/lib/ParkingPlus/LprImagesWebServer/config/basic_auth_users
    fi
}

InstalaConcentrator () {
#Funcao responsavel por instalar / atualizar o Wps Lpr Concentrador
    cd /instalacoes/
    echo
    echo -e "$AMARELO""----------------------------------------------""$CINZA_CLARO"
    echo -e "$AMARELO""----- INSTALACAO DO WPS LPR CONCENTRADOR -----""$CINZA_CLARO"
    echo -e "$AMARELO""----------------------------------------------""$CINZA_CLARO"
    echo
    if [ $SO = "deb" ]
    then
        rm -f /instalacoes/wpslprconcentratorservice_$VERSAO-1_all.deb
        echo -e "DIGITE A SENHA DA "$VERDE"INTRANET"$CINZA_CLARO""
        while true
        do
            wget -c -P /instalacoes/ https://intranet.parkingplus.com.br/pub/Parking%20Plus/ParkingPlus%20-%207/Releases/$VERSAO/ParkingPlus-$VERSAO/Linux/wpslprconcentratorservice/Instalacao/wpslprconcentratorservice_$VERSAO-1_all.deb --http-user=$USUARIO --ask-password --no-check-certificate
            if [ $? -eq 0 ]
            then
                break
            else
                echo -e ""$VERMELHO"Senha incorreta. Tente novamente."$CINZA_CLARO""
            fi
        done
        dpkg -i /instalacoes/wpslprconcentratorservice_$VERSAO-1_all.deb
    else
        rm -f /instalacoes/wpslprconcentratorservice-$VERSAO-1.noarch.rpm
        echo -e "DIGITE A SENHA DA "$VERDE"INTRANET"$CINZA_CLARO""
        while true
        do
            wget -c -P /instalacoes/ https://intranet.parkingplus.com.br/pub/Parking%20Plus/ParkingPlus%20-%207/Releases/$VERSAO/ParkingPlus-$VERSAO/Linux/wpslprconcentratorservice/Instalacao/wpslprconcentratorservice-$VERSAO-1.noarch.rpm --http-user=$USUARIO --ask-password --no-check-certificate
            if [ $? -eq 0 ]
            then
                break
            else
                echo -e ""$VERMELHO"Senha incorreta. Tente novamente."$CINZA_CLARO""
            fi
        done
        rpm -Uhv /instalacoes/wpslprconcentratorservice-$VERSAO-1.noarch.rpm
    fi
    cd /etc/WpsLprConcentrator
    tr -d '0' < wpslprconcentrator.sample.properties > wpslprconcentrator.properties
    mv logback.sample.xml logback.xml
    systemctl daemon-reload
    systemctl restart WpsLprConcentrator
    systemctl enable WpsLprConcentrator
    rm -f /etc/WpsLprConcentrator/wpslprconcentrator.sample.properties
    rm -f /etc/WpsLprConcentrator/logback.sample.xml
}

BackupConfigJson () {
#Funcao que faz backup do arquivo config.json como oculto (Ex.: .bkp_config.json1) no diretorio /instalacoes/
    origem="/var/lib/ParkingPlus/WpsLpr/config/config.json"
    destino="/instalacoes/.config.json"
    contador=1

    while [ -e "${destino}_bkp_${contador}" ]; do
    contador=$((contador + 1))
    done

    cp "$origem" "${destino}_bkp_${contador}"
    echo "Arquivo copiado para ${destino}_bkp_${contador}"
}

MenuHarpia () {
#Funcao que insere automaticamente o cadastro de camera no config.json
    local id_camera=1
    local wps_topic
    local ip_camera
    local user_camera
    local senha_camera
    local add_nova_cam=1
    local fabricante_camera

    if [ "$ACAO" = "INSTALACAO" ]
    then
        echo -e "$VERDE" "-----------------"
        echo -e "$VERDE" "| "$CINZA_CLARO"1 - SIM"$VERDE"       |"
        echo -e "$VERDE" "-----------------"
        echo -e "$VERDE" "| "$CINZA_CLARO"2 - "$VERMELHO"NAO, SAIR"$VERDE" |"
        echo -e "$VERDE" "-----------------""$CINZA_CLARO"
        read -p "GOSTARIA DE REALIZAR O CADASTRO DA(S) CAMERA(S) NO ARQUIVO DE CONFIGURACAO? " ADD_CAM
        echo
    else
        id_camera=$(($(cat /var/lib/ParkingPlus/WpsLpr/config/config.json |grep camera_id |tail -n1 |cut -d: -f 2 | sed 's/\"\|,//g') + 1))
        ADD_CAM=1
    fi
    case "$ADD_CAM" in
        1)
            cp /var/lib/ParkingPlus/WpsLpr/config/config.json /instalacoes/.bkp_config.json

            if [ "$ACAO" = "INSTALACAO" ]
            then
                echo -e "[\n  {\n    \""region_ocr\"": \""brazil\""\n  },\n" > /var/lib/ParkingPlus/WpsLpr/config/config.json
            else
                sed -i '$d' /var/lib/ParkingPlus/WpsLpr/config/config.json
                sed -i '$d' /var/lib/ParkingPlus/WpsLpr/config/config.json
                echo -e "  }," >> /var/lib/ParkingPlus/WpsLpr/config/config.json   
            fi
            
            read -p "DIGITE QUAL SERA O NOME DE USUARIO DA CAMERA (Ex.: wps / admin)? " user_camera
            read -p "DIGITE QUAL SERA A SENHA DA CAMERA (Ex.: senhacamera)? " senha_camera
            
            while [ $add_nova_cam -eq 1 ]
            do
                echo
                read -p "DIGITE QUAL SERA O NOME DO TOPICO (Ex.: ENT_1 / SAI_1)? " wps_topic
                read -p "DIGITE QUAL SERA O IP DA CAMERA (Ex.: 125.125.10.211)? " ip_camera
                read -p "DIGITE O NUMERO RELATIVO AO NOME DO FABRICANTE DA CAMERA (Ex.: 1 - intelbras | 2 - hikvision | 3 - positivo)? " fabricante_camera_opcao
                read -p "DIGITE O NUMERO RELATIVO AO TIPO DE VEICULO QUE SERA LIDO A LPR (1 - CARRO | 2 - MOTO) (Ex.: 1)":  tipo_veiculo

                #Validacao OCR-Mode
                case "$tipo_veiculo" in
                    2)
                        ocr_mode=1
                        ;;
                    *)
                        ocr_mode=0
                        ;;
                esac

                #Validacao Fabricante
                case "$fabricante_camera_opcao" in
                    2) 
                        fabricante_camera=hikvision
                        ;;
                    3)
                        fabricante_camera=positivo
                        ;;
                    *)
                        fabricante_camera=intelbras
                        ;;
                esac

                echo -e "  {\n    \""camera_id\"": \"""$id_camera"\"",\n    \""camera_type\"": \""lpr\"",\n    \""camera_brand\"": \"""$fabricante_camera"\"",\n    \""wps_topic\"": \"""$wps_topic"\"",\n    \""camera_ip\"": \"""$ip_camera"\"",\n    \""user\"": \"""$user_camera"\"",\n    \""password\"": \"""$senha_camera"\"",\n    \""channel_dvr\"": \""1\"",\n    \""frame_ocr_rate\"": 30,\n    \""roi_size_x\"": 1280,\n    \""roi_size_y\"": 720,\n    \""roi_x\"": 0,\n    \""roi_y\"": 0,\n    \""limiar\"": 20,\n    \""plate_size_min\"": 0,\n    \""plate_size_max\"": 0,\n    \""image_size\"": 0,\n    \""ocr_mode\"": "$ocr_mode",\n    \""ocr_time\"": 1,\n    \""sector_id\"": 1,\n    \""parking_name\"": \""\"",\n    \""protocol\"": \""udp\"",\n    \""power_led\"": 40,\n    \""publish_interval\"": 1000,\n    \""parking_spaces_quantity\"": 1,\n    \""park_ids\"": []" >> /var/lib/ParkingPlus/WpsLpr/config/config.json

                echo
                echo -e "$VERDE" "-----------------"
                echo -e "$VERDE" "| "$CINZA_CLARO"1 - SIM"$VERDE"       |"
                echo -e "$VERDE" "-----------------"
                echo -e "$VERDE" "| "$CINZA_CLARO"2 - "$VERMELHO"NAO, SAIR"$VERDE" |"
                echo -e "$VERDE" "-----------------""$CINZA_CLARO"

                read -p "GOSTARIA DE ADICIONAR UMA NOVA CAMERA (Ex.: 1)? " add_nova_cam

                if [ $add_nova_cam = 1 ]
                then
                    id_camera=$(($id_camera+1));
                    echo -e "  }," >> /var/lib/ParkingPlus/WpsLpr/config/config.json
                else
                    echo -e "  }\n]" >> /var/lib/ParkingPlus/WpsLpr/config/config.json
                    add_nova_cam=0
                fi
            done
            ;;
        2)
            echo
            echo "SAINDO DO SCRIPT..."
            sleep 2
            exit 0
            ;;
        *)
            echo
            echo -e "OPCAO "$VERMELHO"INVALIDA"$CINZA_CLARO", SAINDO DO SCRIPT..."
            sleep 2
            exit 2
            ;;
    esac
}

BaixaPumatronix () {
#Funcao que baixa os pacotes para funcionamento das cameras Pumatronix
    iptables -I INPUT -p tcp --dport 51000 -j ACCEPT
    ln -s /usr/bin/python2.7 /usr/bin/python
    pip install --upgrade gdown

    if [ $SO = "deb" ]
    then
        gdown 1hyciIStW6RNvyCPVj4GCZTguJPUSU5BO          #jidosha_deb
        apt install python2 -y
        apt install python2.7 -y
        dpkg --force-all -i jidosha-srv-1.7.0-RC1-x86_64.deb
    else
        gdown 1UX2VcgzUBjXkQ_mln9tZY3dsAOEG2cNk          #jidosha_rpm
        yum install python2 -y
        yum install python2.7 -y
        rpm -ivh jidosha-srv-1.5.6+03c32ed-x86_64.rpm --nodeps
    fi

    gdown 1btSfJFrly94n2GWsP1Y1_96VV4vl-pQe              #JDongleTool
    mv JDongleTool.unknown JDongleTool
    mv JDongleTool /opt/jidoshaserver/
    cd /opt/jidoshaserver/
    chmod 777 JDongleTool

    systemctl start jidoshaserver
    systemctl enable jidoshaserver
    systemctl restart jidoshaserver

    ./JDongleTool -c
}

VerificaTipoCam () {
#Funcao que verifica qual o tipo de camera que vai ser configurada no servidor
    echo
    echo -e "$VERDE" "------------------"
    echo -e "$VERDE" "| "$CINZA_CLARO"1 - HARPIA"$VERDE"     |"
    echo -e "$VERDE" "------------------"
    echo -e "$VERDE" "| "$CINZA_CLARO"2 - PUMATRONIX"$VERDE" |"
    echo -e "$VERDE" "------------------""$CINZA_CLARO"
    read -p "ESCOLHA A CAMERA QUE SERA CONFIGURADA (Ex.: 1 OU 2)? " ESCOLHE_ACAO
    case "$ESCOLHE_ACAO" in
        1)
            echo
            echo -e "Opcao escolhida: "$VERDE"HARPIA"$CINZA_CLARO""
            TIPO_CAM="HARPIA"
            ;;
        2)
            echo
            echo -e "Opcao escolhida: "$VERDE"PUMATRONIX"$CINZA_CLARO""
            TIPO_CAM="PUMATRONIX"
            ;;
        *)
            echo
            echo -e " --- Opcao "$VERMELHO"INVALIDA"$CINZA_CLARO", escolha 1 ou 2. ---"
            echo
            VerificaTipoCam
            return
            ;;
    esac
}

AtualizaEngine () {
#Funcao que atualiza a Engine
    echo "em construcao"
}

###########################################################################
############################## INICIO SCRIPT ##############################
###########################################################################

echo
echo -e "$AMARELO""-------------------------------------------------------------------""$CINZA_CLARO"
echo -e "$AMARELO""----- BEM VINDO AO SCRIPT DE INSTALACAO / ATUALIZACAO LPR !!! -----""$CINZA_CLARO"
echo -e "$AMARELO""-------------------------------------------------------------------""$CINZA_CLARO"
echo
sleep 1
echo -e "$AMARELO""---------------------------------------------------------------------------------------------""$CINZA_CLARO"
echo -e "$AMARELO""-----   POR MOTIVOS DE ETICA E SEGURANCA, ESSE SCRIPT "$VERMELHO"NAO"$AMARELO" ARMAZENA SENHA DA INTRANET.   -----""$CINZA_CLARO"
echo -e "$AMARELO""----- IDEAL QUE SEJA EXECUTADO PELO USUARIO "$VERMELHO"ROOT"$AMARELO", EVITANDO QUAISQUER ERROS DE PERMISSAO -----""$CINZA_CLARO"
echo -e "$AMARELO""---------------------------------------------------------------------------------------------""$CINZA_CLARO"
echo
sleep 3

VerificaSO
VerificaInternet
MenuEscolheAcao

case "$ACAO" in
    "CONFIGURACAO_CAMERA")
        cd /instalacoes/
        MenuHarpia
        break
        ;;

    "ATUALIZACAO")
        cd /instalacoes/
        VerificaVersao
        InstalaConcentrator
        InstalaWebImages
        ;;

    "ENGINE")
        AtualizaEngine
        ;;
    
    "INSTALACAO")
        AtualizaTimezone
        sudo mkdir -p /instalacoes /WPSBrasil
        cd /instalacoes
        AtualizaRepositorios
        ServPython
        InstalaDocker
        InstalaDockerCompose
        VerificaVersao
        InstalaPkPlusCli
        NvidiaContainerToolkit
        VerificaPlacaDeVideo
        if [ $POSSUI_GPU -eq 1 ]
        then
            InstalaDriversNvidia
        fi
        ControleGpu
        NomeMaquina
        DesabilitaDobroLog
        PerformanceMaquina
        InstalaConcentrator
        InstalaWebImages
        VerificaTipoCam
        if [ "$TIPO_CAM" = "PUMATRONIX" ]
        then
            BaixaPumatronix
        else
            read -p "DIGITE A VERSAO DA ENGINE A SER BAIXADA (Ex.: 2.6.0, 2.7.0 OU 2.9.0): " VERSAO_ENGINE
            ValidaVersaoEngine
            read -p "DIGITE A CHAVE PARA DOWNLOAD DO MQTT E / OU ENGINE: " CHAVE_DOWNLOAD
            ValidaChave
            if [ $VALIDA_VERSAO_ENGINE -ge 27 ]
            then
                BaixaMqtt
            fi
            BaixaEngine
            MenuHarpia
        fi
esac
