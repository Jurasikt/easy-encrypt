#!/bin/bash
val="$(openssl version)"
if [ "${val%% *}" != 'OpenSSL' ]; then 
    echo "Command openssl cannot be found"
    exit
fi

clear
while :
do
    echo "What do you want to do?"
    echo "   1) Generate new pait pub/private key"
    echo "   2) Encrypt large file"
    echo "   3) Decrypt file"
    echo "   4) Exit"
    read -p "Select an option [1-4]: " option
    case $option in
        1)
            read -p "File name: " -e -i key FILENAME
            openssl genrsa -out "$FILENAME.pem" 2048
            openssl rsa -in "$FILENAME.pem" -pubout > "$FILENAME.pub"
            echo "RSA Key Pairs was created"
            echo "The private key is never shared, only the public key is used to encrypt the random symmetric cipher"
            echo ""
            ;;
        2)
            read -p "Select the file for an encrypt: " FILENAME
            read -p "Select the public key(*.pub): " PUB
            if [ -e $FILENAME ] && [ -e $PUB ]; then
                openssl rand -base64 32 > passwd.txt
                openssl enc -aes-256-ecb -a -salt -in $FILENAME -out encryptfile.enc -pass file:passwd.txt
                openssl rsautl -encrypt -pubin  -inkey $PUB -in passwd.txt -out passwd.txt.enc
                rm passwd.txt encryptfile.enc passwd.txt.enc
                NAME=$(basename "$FILENAME")
                zip "$NAME.zip" encryptfile.enc passwd.txt.enc
            else
                echo "Files $FILENAME or $PUB do not exsist"
            fi
            echo ""
            ;;
        3)
            read -p "Select the file for a decrypt: " FILENAME
            read -p "Select the private key(*.pem): " PRIVATE
            if [ -e $FILENAME ] && [ -e $PRIVATE ]; then
                unzip $FILENAME
                if [ -e passwd.txt.enc ] && [ -e encryptfile.enc ]; then
                    NAME="${FILENAME%.*}"
                    openssl rsautl -decrypt -inkey $PRIVATE -in passwd.txt.enc -out passwd.txt
                    openssl enc -d -aes-256-ecb -a -in encryptfile.enc -out $NAME -pass file:passwd.txt
                    rm passwd.txt passwd.txt.enc encryptfile.enc
                    echo "The file $NAME has been successfully decrypted."
                else
                    echo "Error. File encryptfile.enc not found in archive"
                fi
            else 
                echo "File $FILENAME not found"
            fi
            echo ""
            ;;
        *)
            exit;;
    esac
done