## Digitally sign your email on the MTA side

Why sign your email directly on the MTA (here we will talk about Postfix MTA) ? I don’t find a simple webmail client for my email server that include a S/MIME and/or PGP functionality to sign/encrypt outgoing messages.

So I found and change a little bit a script that get the outgoing message on the MTA and sign them with OpenSSL. The steps are:
– A running Postfix server
– Create the user account that will run the signing script and lock the account to prevent logging in:

    useradd -M pfsigner
    usermod -L pfsigner

– Create the folder /var/spool/signing. This folder will be used to store temporary message header and content

    chmod 700 /var/spool/signing
    chown pfsigner:pfsigner /var/spool/sign

– Edit your /etc/postfix/master.cf . We will add a new TCP port for the smtpd. This port will be used on your mail/webmail client SMTP configuration. Add these lines:

    2525      inet  n       -       -       -       -       smtpd
      -o content_filter=sign:dummy
    sign      unix  -       n       n       -       10      pipe
      flags=Rq user=pfsigner null_sender=
      argv=/usr/local/bin/sign.sh -f ${sender} -- ${recipient}

– request your certificate and export the certificate+private key to a pfx file

    openssl pkcs12 -inkey /etc/letsencrypt/live/<domain>/privkey.pem -in /etc/letsencrypt/live/<domain>/fullchain.pem -export -out <domain>.pfx

– convert your pfx file to pem (use your email name in the pem filename as shown below). If your email is youremail@yourdomain.com, use the following command:

    openssl pkcs12 -in <domain>.pfx -out youremail@yourdomain.com.pem -nodes

– create the folder certs

    mkdir -p /home/smime

– copy the certificate to the certs folder created above
– copy sign.sh the script file to /usr/local/bin/sign.sh

You can now configure your favorite email client and do not forget to specify port TCP 2525 for the SMTP settings to send your signed emails.

## Information
Used wiki at openssl https://wiki.openssl.org/index.php/Command_Line_Utilities#Mail_.2F_SMIME

## Thanks
Script info taken from site https://www.shellandco.net/digitally-sign-your-email-on-the-mta-side/
