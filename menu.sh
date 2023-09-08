#!/bin/bash
# menu.sh - Akash wallet handler is an easy way to create addresses and manage your AKT.


#Detect self-contained build
if [ -d akash-wallet-handler ]; then
echo "Detected self contained build"
echo "Building Akash Docker container"
cd akash-wallet-handler
docker build -t akash . > build_akash.log
else

if docker ps | grep -q akash
then
    STATUS="Running"
else
    STATUS="Not running"
    echo "Building Akash Docker container"
    docker build -t akash . > build_akash.log
fi
fi

#Read existing variables
if [ -f variables ]; then
. variables
fi

INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$

# get text editor or fall back to vi_editor
vi_editor=${EDITOR-vi}

# trap and delete temp files
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

#
# Purpose - display output using msgbox 
#  $1 -> set msgbox height
#  $2 -> set msgbox width
#  $3 -> set msgbox title
#
function display_output(){
        local h=${1-10}                 # box height default 10
        local w=${2-41}                 # box width default 41
        local t=${3-Output}     # box title 
        dialog --backtitle "Akash Wallet Handler" --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
}
#
# Purpose - display current system date & time
#
function show_date(){
        echo "Today is $(date) @ $(hostname -f)." >$OUTPUT
    display_output 6 60 "Date and Time"
}
#
# set infinite loop
#
while true
do

if docker ps | grep -q akash
then
    STATUS="Running"
else
    STATUS="Not running"
        if [[ -d data && -f variables ]]; then
echo "Houston we have a problem!, Akash needs to be started"
read -p "Start Akash now? (y/n)? " choice
case "$choice" in
  y|Y ) echo "yes" ; echo "Starting Akash in Docker" ; docker run -itd --env-file=variables --rm --name akash -v $(pwd)/data:/root/.akash akash > start_akash.log ; echo "Akash now started!" ; STATUS="Running";;
  n|N ) echo "no" ; echo "Data and variables exist, must run Akash to use this wallet." ; sleep 5 ; exit;;
  * ) echo "invalid" ; return;;
esac

        fi

fi

BALANCE=$(docker exec -it akash /bin/bash -c 'akash query bank balances --node $AKASH_NODE $AKASH_ACCOUNT_ADDRESS' | grep amount)
NETWORK=$(docker exec -it akash /bin/bash -c 'akash status' | jq -r .NodeInfo.network)

if [[ -d data && -f variables ]]; then
echo "Locked data and variables"
SETUP_MODE=0
dialog --clear  --help-button --backtitle "Akash" \
--title "[ A K A S H - W A L L E T - H A N D L E R ]" \
--menu "Akash Status : $STATUS \n\
Akash Connections : $AKASH_NODE \n\
Akash $BALANCE \n\
Akash Network $NETWORK \n\
\n\
You can use the UP/DOWN arrow keys, the first \n\
letter of the choice as a hot key, or the \n\
number keys 1-9 to choose an option.\n\
Choose the TASK" 25 50 7 \
Setup "First time setup and wallet creation" \
Deploy "Deploy a Docker container on Akash Network" \
Show "Show wallet address and QR code" \
Check "Check balance" \
Send "Send AKT" \
Node "Run full-node" \
Export "Export private keys and mnemonic" \
Run "Run command against CLI" \
Exit "Exit to the shell" 2>"${INPUT}"
menuitem=$(<"${INPUT}")
else
SETUP_MODE=1
dialog --clear  --help-button --backtitle "Akash" \
--title "[ M A I N - M E N U ]" \
--menu "Akash must be setup for the first time" 15 50 4 \
Setup "First time setup and wallet creation" \
Exit "Exit to the shell" 2>"${INPUT}"
menuitem=$(<"${INPUT}")
fi


#USE #return to break out of loops

### display main menu ###

#function sayhello(){
#       local n=${@-"anonymous person"}
        #display it
#       dialog --title "Hello" --clear --msgbox "Hello ${n}, let us be friends!" 10 41
#}


function pass() {
        pass=$(dialog --inputbox "Password for existing wallet $AKASH_KEY_NAME?" 0 0  --output-fd 1)

if [ -z $pass ]; then
echo "Password cannot be blank. Please retry in 5 seconds."
sleep 5
pass
elif (( $(echo $pass | wc -c) <= 8 )); then
echo "Password cannot be less than 8 characters. Please retry in 5 seconds."
sleep 5
pass
else
export pass
return
fi
}


function reset() { 
if [ -d "data" ]
then
read -p "Destructive action! Continue (y/n)? " choice
case "$choice" in
  y|Y ) echo "yes" ; sudo rm -rf data ; echo "Data directory wiped, you can now continue with setup.";;
  n|N ) echo "no";;
  * ) echo "invalid";;
esac
fi
}

function run_command(){
        command=$(dialog --inputbox "Command to run - example : help" 0 0  --output-fd 1)
export command

}
function run_another(){
read -p "Run another command? Continue (y/n)? " choice
case "$choice" in
  y|Y ) echo "yes" ; run_command;;
  n|N ) echo "no"; return;;
  * ) echo "invalid"; return;;
esac
}

function send_akt() {
        receiveraddress=$(dialog --inputbox "Where to send AKT (address)?" 0 0  --output-fd 1)
        receiveramount=$(dialog --inputbox "How much AKT (amount)?" 0 0  --output-fd 1)
        export receiveramount
        export receiveraddress
}
#function input_receiver_amount() {
#        receiveramount=$(dialog --inputbox "How much AKT (amount)?" 0 0  --output-fd 1)
#        receiveramount=$((1000*$receiveramount))
#        export receiveramount
#}
function input_password() {

if [ -d "data" ]
then
    echo "Data Directory exists. Cannot continue with initial setup.  Please backup and delete data folder at $(pwd)/data to continue."
sleep 10
return
fi
        pass=$(dialog --inputbox "Password for new wallet?" 0 0  --output-fd 1)


if [ -z $pass ]; then
echo "Password cannot be blank. Please retry in 5 seconds."
sleep 5
input_password
elif (( $(echo $pass | wc -c) <= 8 )); then
echo "Password cannot be less than 8 characters. Please retry in 5 seconds."
sleep 5
input_password
else
./setup-wallet.sh $pass 
SETUP_MODE=0
finish
fi


}

function show_address(){
#. variables
#        echo "Setup finished succesfully at $(date) you can now send funds to $AKASH_ACCOUNT_ADDRESS. Your account must have funds before you can deploy an instance." >$OUTPUT

dialog --clear
qrencode -t ASCIIi $(docker exec -it akash /bin/bash -c "echo $pass | akash keys list | grep address | cut -d ':' -f2 | cut -c 2-")
echo "Your AKT wallet address is :"
docker exec -it akash /bin/bash -c "echo $pass | akash keys list | grep address | cut -d ':' -f2 | cut -c 2-" ; echo "" ;
sleep 10
#> qrcode.log
#cat qrcode.log > $OUTPUT
#    display_output 0 600 "Your AKT Wallet Address"
#dialog --no-collapse --msgbox "$(cat qrcode.log)" 640 480
#dialog --stdout --tailbox qrcode.log 0 0

#sleep 10
}

function finish(){
. variables
        echo "Setup finished succesfully at $(date) you can now send funds to $AKASH_ACCOUNT_ADDRESS. Your account must have funds before you can deploy an instance." >$OUTPUT
    display_output 0 0 "Setup Finished"
}

function akashlytics(){


if [[ "$OSTYPE" == "linux-gnu"* ]]; then

if [ -f ./Akashlytics\ Deploy-0.3.1.AppImage ]; then
echo "Already have the latest AppImage"
./Akashlytics\ Deploy-0.3.1.AppImage
else
wget https://storage.googleapis.com/akashlytics-deploy-public/Akashlytics%20Deploy-0.3.1.AppImage
chmod +x ./Akashlytics\ Deploy-0.3.1.AppImage
echo "Now showing your mnemonic phrase, you will copy and paste this into Akashlytics the first time."
echo ""
echo "Your mnemonic recovery phrase is :"
docker exec -it akash /bin/bash -c "akash keys mnemonic"
echo "Copy this to your clipboard now"
sleep 10
./Akashlytics\ Deploy-0.3.1.AppImage
echo "Congratulations - you've made it one step closer to deploying on Akash"
echo "To make getting started easier we invite you to goto the Akash Faucet at this time to claim your AKT"
echo "The faucet will require you to authenticate with a Github account." 
echo "-----"
echo "Faucet Link : https://drip.akash.network"
echo "Your AKT wallet address : $AKASH_ACCOUNT_ADDRESS"
echo "-----"
echo "Sleeping for 120 seconds for you to access the Faucet"
#echo "You can continue to use akash-wallet-handler to send and receive AKT from Akashlytics"
sleep 120
fi

elif [[ "$OSTYPE" == "darwin"* ]]; then

if [ -f ./Applications/Akashlytics\ Deploy.app ]; then
open -a ./Applications/Akashlytics\ Deploy.app
else
wget https://storage.googleapis.com/akashlytics-deploy-public/Akashlytics%20Deploy-0.3.1.dmg
echo "Akashlytics has been downloaded to $(pwd).  Please install the Application now. Waiting 15 seconds until trying to detect..."
sleep 15
until [ -f ./Applications/Akashlytics\ Deploy.ap ]
do
     sleep 30
done

echo "Now showing your mnemonic phrase, you will copy and paste this into Akashlytics the first time."
echo ""
echo "Your mnemonic recovery phrase is :"
docker exec -it akash /bin/bash -c "akash keys mnemonic"
echo "Copy this to your clipboard now"
sleep 10
./Applications/Akashlytics\ Deploy.app
echo "Congratulations - you've made it one step closer to deploying on Akash"
echo "To make getting started easier we invite you to goto the Akash Faucet at this time to claim your AKT"
echo "The faucet will require you to authenticate with a Github account." 
echo "-----"
echo "Faucet Link : https://drip.akash.network"
echo "Your AKT wallet address : $AKASH_ACCOUNT_ADDRESS"
echo "-----"
echo "Sleeping for 120 seconds for you to access the Faucet"
#echo "You can continue to use akash-wallet-handler to send and receive AKT from Akashlytics"
fi

elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "$OSTYPE is not supported at this time"
elif [[ "$OSTYPE" == "msys" ]]; then
        echo "$OSTYPE is not supported at this time"
elif [[ "$OSTYPE" == "win32" ]]; then
        echo "$OSTYPE is not supported at this time"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "$OSTYPE is not supported at this time"
else
        echo "$OSTYPE is not supported at this time"
fi

}


function deploy () {
cmd=(dialog --separate-output --checklist "Select options:" 0 0 0)
options=(1 "Deploy using Akashlytics (GUI)" on    # any option can be set to default to "on"
         2 "Deploy using this tool" off
         3 "Deploy using React web app" off )
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
            akashlytics
            ;;
        2)
            deploy-now
            ;;
        3)
            react
            ;;
        *)
            break
            ;;
    esac
done
}


function setup () {
cmd=(dialog --separate-output --checklist "Select options:" 0 0 0)
options=(1 "Create wallet and first run!" on    # any option can be set to default to "on"
         2 "Backup private keys" off
         3 "Reset / Delete Data Directory" off )
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
            input_password
            ;;
        2)
            ./backup-private-keys.sh ; echo "Showing keys for 10 seconds!" ; sleep 10
            ;;
        3)
            reset
            ;;
        4)
           update_rpcallow
            ;;
        *)
            break
            ;;
    esac
done
}

# make decsion 
case $menuitem in
        Setup) setup;;
        Deploy) deploy;;
        Node) ./run-full-node.sh;;
        Export) ./backup-private-keys.sh  ; echo "Showing keys for 10 seconds!" ; sleep 10;;
        Show) pass ; show_address ;;
        Check) echo "Showing balance for 10 seconds!" ; docker exec -it akash /bin/bash -c 'akash query bank balances --node $AKASH_NODE $AKASH_ACCOUNT_ADDRESS' ; sleep 10;;
        Run) run_command ; docker exec -it akash /bin/bash -c "akash $command" ; sleep 5 ; run_another;;
        Send) send_akt ; pass ; docker exec -it akash /bin/bash -c "echo $pass | akash tx bank send "'"$AKASH_ACCOUNT_ADDRESS"'" $receiveraddress ${receiveramount}uakt --fees 200uakt --chain-id akashnet-2 -b async -y";;
        Exit) echo "Bye"; break;;

esac

done

# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
