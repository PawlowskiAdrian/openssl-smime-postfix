#!/bin/bash
# SMTP Signer - POSIX Shell Implementation (using sed)

USERNAME="pfsigner"
SIGN_DIR="/var/spool/sign"
CERT_DIR="/home/smime"
SENDMAIL="/usr/sbin/sendmail -G -i"
OPENSSL="/usr/bin/openssl"
CERT_FILE="${CERT_DIR}/$2.pem"

E_TEMPFAIL=75

cd ${SIGN_DIR} || {
  printf "${SIGN_DIR} does not exist"
  exit ${E_TEMPFAIL}
}

# TRAP DEFINITION
# Number        SIG             Meaning
# 0             0               On exit from shell
# 1             SIGHUP          Clean tidyup
# 2             SIGINT          Interrupt
# 3             SIGQUIT         Quit
# 6             SIGABRT         Abort
# 9             SIGKILL         Die Now (cannot be trap'ped)
# 14            SIGALRM         Alarm Clock
# 15            SIGTERM         Terminate
trap "rm -f in.$$ body.$$ body2.$$ header1.$$ header2.$$ header.$$ signed.$$" 0 1 2 3 15

# Get the outgoing message : header and body
cat >in.$$

# get the header and store it in the file header.$$
sed '/^$/q' <in.$$ >header1.$$
sed '$d' <header1.$$ >header.$$

# find the line that begin with Content-type in the header text
CONTENT_TYPE=`sed -n '/Content-Type:/p' <header1.$$`

printf "\r\n" >body.$$
sed '1,/^$/ d' <in.$$ >>body.$$

# You can uncomment the following both lines if you want to troubleshoot and see the content of the header and message body in the log file user.log
#logger -f header.$$
#logger -f body.$$

# If a certificate exist and the email is not already signed, sign it with openssl
if [[ -f "${CERT_FILE}" ]] && [[ $CONTENT_TYPE != *"signed"* ]]; then
  # Sign mail and relay
  MSG="Signed mail from $2"

  CONTENT_TYPE_BODY=`sed -n '/Content-Type/,+1p' header.$$`
  printf "${CONTENT_TYPE_BODY}\n" > body2.$$
  cat body.$$ >>body2.$$
  sed '/Content-Type/,+1 d' <header.$$ >header2.$$

  # Sign the message body with OpenSSL
  ${OPENSSL} cms -sign -signer ${CERT_FILE} -noattr -nodetach -in body2.$$ -out signed.$$
  sed '/Content-Type/,+1 d' <header.$$ >header2.$$

  # Concaetnante header and the signed message and send it using sendmail tool
  cat header2.$$ signed.$$ | ${SENDMAIL} "$@"
else
  # Relay without signing
  MSG="Unsigned mail from $2 because message already signed"
  cat in.$$ | ${SENDMAIL} "$@"
fi

STATUS=$?

if [ "${STATUS}" -eq 0 ]; then
  LOG_LEVEL="notice"
else
  LOG_LEVEL="err"
fi
logger -p "mail.${LOG_LEVEL}" -t "sign.sh" "${MSG}"

exit ${STATUS}
