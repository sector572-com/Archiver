Archiver
========

Backup Utility Script for Unix/Linux
Copyright(c) 2018 - sector572.com

Description:  A utility script that can automatically archive directories and
              files. It can optionally compress and encrypt the backup files.

Disclaimer:   This product is free and provided as is with no warranty of any
              kind. You may use it at your own risk. You may also distribute
              it so long as you leave the file information and disclaimer
              intact.

              By using this script, sector572.com is not responsible for
              any damages it may cause. You should probably test it on non-
              production data to ensure it works as you expect.

Homepage:     https://www.sector572.com

Instructions:

1) You need to specify the app_home directory. To do this, edit the
   ch_archive.sh script look for the line with app_home=""

   Let's suppose you extracted the Archiver package into 
   /home/codershaven/Archiver,

   The line:

   app_home=""

   should be replaced with:

   app_home="/home/codershaven/Archiver"

   Save the changes when you're done.

2) Next, you're going to need to change the conf/archive.conf file.

   Specifically:

   GPG_RECIPIENTS=""

   and

   FILE_LIST=""

   So, assuming you've installed the software in /home/codershaven/Archiver,

   You will need to change the line:

   GPG_RECIPIENTS=""

   with

   GPG_RECIPIENTS="/home/codershaven/Archiver/conf/gpg_recipients"

   You will also need to change the line:

   FILE_LIST=""

   with

   FILE_LIST="/home/codershaven/Archiver/conf/file_list"

3) Edit the file /home/codershaven/Archiver/conf/file_list and add one
   or more absolute paths to files or directories (one per line) in the
   file.

4) If you've enabled GPG encryption, add one or more recipient email
   addresses located in your gpg keyring to the file
   /home/codershaven/Archiver/conf/gpg_recipients (one per line).

   You can use the command:

       gpg --list-keys

   to locate these recipients. If you don't have any, you will need to add
   or create new keys in your keyring.

More information about the tool will be made available on the website.
