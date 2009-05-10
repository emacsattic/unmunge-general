;;; unmunge-general.el --- Change address/sig with context in gnus
;; This file is not part of GNU Emacs
;; This is released under the GNU Public License

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this GNU Emacs; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;; LCD Archive Entry:
;; unmunge-general|Gareth Owen|gowen@ma.man.ac.uk|
;; Change signature file with context in gnus|
;; 16-Jan-99|version 0.6|

;;; Commentary
;; Do you filter your email?  Would you like to make it easier on yourself by
;; having a different From: address for different newsgroups, and maybe a
;; different one for email to different mailing lists (i.e. mail groups)?
;; Well this the package for you.
;;
;; Do you find yourself editing your signature file after it's in the message
;; buffer because it isn't suitable for for the context (an email to your boss
;; with a quote extolling idleness)?  Want posts to rec.music.leonard-cohen to
;; have a line of Cohen in the signature or those to comp.emacs to have a link
;; to your emacs homepage?  Well now you can.

;;; Copyright Gareth Owen
;; All feedback gratefully accepted <gowen+usenet@ma.man.ac.uk>
;; Homepage http://www.geocities.com/drgazowen/lisp/

;; Version 0.6.1 : Mon Jul 12 10:34:12 BST 1999
;;; History:
;; 0.6 => 0.6.1 Bug fix after "upgrade" from GNU Emacs 19.34 to 20.2 broke
;;            the behaviour of message-fetch-field when the field was empty.
;;            (19.34 returned "", 20.2 returns `nil').

;; 0.5 => 0.6 Re-implemented `unmunge-sigfile-function' and
;;            `unmunge-address-function' how they should have been done in
;;            the first place.  This meant I could throw out some ugly code
;;            that trapped quits.  Removed the references to the previous
;;            heuristics methods of determining mail/news names/addresses,
;;            since its all more scientific now.
;;            Added an LCD Archive Entry.

;;
;; 0.4 => 0.5 Some user-options have changed name for consistency
;;            unmunge-sigfile-default is now unmunge-default-sigfile
;;            unmunge-sigfile-mail is now unmunge-mail-sigfile
;;            Added ability to modify mail address/sigs according to email
;;            addresses of recipients.
;;            Added ability to change sig/address on posting, reading modified
;;            To: or Newsgroup: line.
;;            Default values of some user options have changed due to
;;            different handling of mail groups.

;;
;; 0.3 => 0.4 lint-recommended stuff changed.
;;            Modified to use custom, for easier customising in
;;            (X)Emacs 20+.  The group is gnus-various-unmunge
;;            Documentation and example strings improved massively.
;;            Installation instructions changed extensively.
;;            Checked with checkdoc.el
;;            Thanks to Jari Aalto.
;;
;; 0.2 => 0.3 Bug fixes to do with returns of t from unmunge-use-heuristics
;;            checked with checkdoc.el
;;
;; 0.1 => 0.2 Customising signature added.
;;            Longer functions broken into subroutines
;;            Most variables and functions renamed in a consistent manner.

;;; Bugs:
;; i) I'm really bad at spelling "address."  I bet some misspellings
;;            get through.  I also spell customise with an `s'.  Sorry.
;;

;;; Installation:
;; Put the file somewhere where emacs knows about it.  Byte compile it.
;; Put the following in your .gnus.el file
;;    (require 'unmunge-general)
;; This will load the package whenever gnus starts.

;; To use the address munging you must add
;;    (add-hook 'message-header-setup-hook 'unmunge-address-function)
;; to you .gnus.el

;; To use the sig-changer, add
;;    (add-hook 'message-signature-setup-hook 'unmunge-sigfile-function)
;; to you .gnus.el

;; These hooks are called *after* the newsgroup name is inserted in the
;; buffer, so the newsgroup/address can be read from there.

;; Finally, if you're feeling brave you can also use
;; (add-hook 'message-send-hook 'unmunge-postfix-signature)
;; (add-hook 'message-send-hook 'unmunge-postfix-address)
;; which will attempt to parse your To/Newsgroup line on sending, and
;; recommend changes based on the results.

;;; Configuring:
;;
;; Firstly tell emacs what you'd like your email and usenet email address to
;; appear to be in the From: line.  If you don't do this, it defaults to the
;; value of the variable user-mail-address.  Unmunge uses two variable for
;; this purpose.  Include something like the following in your .gnus.el file
;;
;;; (setq unmunge-default-address "address1@my.domain")
;;;	;;This is the default address used for usenet
;;; (setq unmunge-mail-address "address2@my.domain")
;;;	;;This is the default address used for email correspondance.
;;
;; The value of these variables can be variables or functions themselves.  The
;; following is very useful/portable.  Put it in your .emacs or .gnus.el,
;; after your user-mail-address is set, if you set this yourself.
;;
;; (setq unmunge-mail-address user-mail-address)
;; (setq unmunge-default-address
;;       (progn
;;         (string-match "@" user-mail-address))
;;         (replace-match "+usenet@" nil nil user-mail-address)))
;;
;; This adds +usenet to your email address, between your username and the
;; domain e.g gowen@my.domain => gowen+usenet@my.domain which exploits the
;; ability of many common mail transfer agents to cheerfully ignore anything
;; following a "+" in that position.  Check with your ISP/sysadmin that this
;; is the case.
;;
;; For most users, just expressing them as strings will suffice.
;;
;; You can then define any number of variables as addresses and signature
;; files, although this isn't necessary.
;; They can be anything that evaluates to a string, (or nil for the sigs).
;;
;; (setq my-binary-mail-address "gowen+bin@my.domain")
;;
;; (setq my-spam-complaint-address
;;      (progn
;;        (string-match "@" user-mail-address))
;;        (replace-match "+spam@" nil nil user-mail-address)))
;;
;; Similarly
;;
;; (setq unmunge-sigfile-linux "~/.signature.linux")

;; Now you need only set up your lists of pairs of newsgroup names and email
;; addresses as the variable unmunge-alist.

;; An example:
;; (setq unmunge-alist
;;      '(("alt.religion.emacs" . unmunge-default-address)
;;	  ("emacs" . "gowen+emacs@my.domain")
;;        ("alt.binaries" . my-binary-mail-address))
;;
;;
;; (setq unmunge-sigfile-alist
;;      '(("alt.fan.warlord" . nil)
;;	  ("emacs" . "~/.signature.emacs)))

;;; We can now set up a similar thing based on email address
;;
;;(setq unmunge-addressee-sigfile-alist
;;      '(("ero2\\|cooper@biol\\|brian@arq\\|owenk001\\|DaveyOwen" . nil)
;;      ;; No sigs for friends and family
;;      ("@ma.man.ac.uk" . "~/.sigfixed")))
;; ;; People in the department get a room/phone number, no one else,

;;; TODO
;;
;; Rewrite newsgroup/address line parsing functions such that
;; i)  They use the message-* internals that are predefined:
;;     i.e. message-news-p
;;          mail-fetch-field
;; ii) They don't rely on things which aren't true after an article get
;; cancelled

;; And we're done.

;; Begin file : unmunge-general.el

;;; Code:
;; If you don't have custom, this will redefine the defcustom macro so that
;; it works like defvar.  This code from the custom homepage.
(eval-and-compile
  (condition-case ()
      (require 'custom)
    (error nil))
  (if (and (featurep 'custom) (fboundp 'custom-declare-variable))
      nil ;; We've got what we needed
    ;; We have the old custom-library, hack around it!
    (defmacro defgroup (&rest args)
      nil)
    (defmacro defface (var values doc &rest args)
       (` (make-face (, var))))
    (defmacro defcustom (var value doc &rest args)
      (` (defvar (, var) (, value) (, doc))))))

(eval-when-compile
  (require 'gnus)
  (require 'cl)
  (require 'message))


;;; CUSTOM OPTIONS
;; First a custom group for the user options.

(defgroup gnus-various-unmunge nil
  "Changing your email address and signature with context."
  :group 'gnus-various)

;;; VARIABLES

(defcustom unmunge-default-address 'user-mail-address
  "*The (usually slightly munged) default usenet email address.
This can be set to anything that evaluates to a string.

For example: a string literal like \"joe.schmo@unix.box\"
or a function or variable that returns a valid address like
(replace-in-string user-mail-address \"@\" \"+usenet@\")

This is used by `unmunge-get-address' when posting to usenet and the
newsgroup name doesn't match any of the regexps in `unmunge-alist'."
  :group 'gnus-various-unmunge)

(defcustom unmunge-mail-address 'user-mail-address
  "*An unmunged email address for private mail.
This can be set to anything that evaluates to a string.

For example: a string literal like \"joe.schmo@unix.box\"
or a function or variable that returns a valid address like
(replace-in-string user-mail-address \"@\" \"+private@\")
or `user-mail-address'.

This is used by `unmunge-get-address' when sending mail and the
email addresses don't match any of the regexps in
`unmunge-addressee-address-alist'"
  :group 'gnus-various-unmunge)

(defcustom unmunge-default-sigfile "~/.signature"
  "*The default usenet signature filename.
This can be set to anything which evaluates to a string, or nil.

For example: \"~/.signature\"
or (if (file-readable-p \"~/.signature.usenet\")
        \"~/.signature.usenet\" \"~/.signature\").

This is used by `unmunge-get-sigfile' when posting to usenet and the
newsgroup name doesn't match any of the regexps in `unmunge-sigfile-alist'"
  :group 'gnus-various-unmunge)

(defcustom unmunge-mail-sigfile 'message-signature-file
  "*The default email signature filename.
This can be set to anything which evaluates to a string, or nil.

For example: \"~/.signature\"
or (if (file-readable-p \"~/.signature.mail\")
        \"~/.signature.mail\" \"~/.signature\").

This is used by `unmunge-get-sigfile' when sending mail and the
email addresses don't match any of the regexps in
`unmunge-addressee-sigfile-alist'."
  :group 'gnus-various-unmunge)

(defcustom unmunge-postfix-skip-confirm nil
"*Set to t to skip confirmation of signature changes on sending mail/news.

It is not recommended that you do this, unless you have found that feature
to work reliably for you in the past."
  :group 'gnus-various-unmunge
  :type 'boolean)

(defcustom unmunge-read-all-addresses t
  "*Set to t if you want to read an entire address line, nil for one address.

If set to nil, only the first address in a list of recipients is used in
determining which signature file / address is used."
  :group 'gnus-various-unmunge)

(defcustom unmunge-read-all-groups t
  "*Set to t if you want to read an entire Newsgroup line, nil for one group.

If set to nil, only the first address in a list of recipients is used in
determining which signature file / address is used."
  :group 'gnus-various-unmunge)

(defcustom unmunge-alist nil
 "*A list of pairs of newsgroup regexps and mail addresses.

A list of dotted pairs, the first being a regexp with which the newsgroup
name is matched, and the second a string, or a function or variable
returning a string, which is a valid email address.  More general regexps
should go at the end.  The matching is done by
`unmunge-mail-address-function'.\n
For example:
((\"spam\" . \"mail+spam@my.domain\")
 (\"xemacs.\" . \"user+xemacs@my.domain\")
 (\"emacs\" . \"user+emacs@my.domain\"))"
:group 'gnus-various-unmunge)

(defcustom unmunge-addressee-address-alist nil
      "*A list of pairs of email address regexps and mail addresses.

A list of dotted pairs, the first being a regexp with which the recipients
email address is matched, and the second a string, or a function or variable
returning a string, which is a valid email address.  More general regexps
should go at the end.  The matching is done by
`unmunge-mail-address-function'.

For example:
((\"owen\" . \"user+family@my.domain\")
 (\"ma.man.ac.uk\" . \"user+work@my.domain\")
 (\"gnu.org\" . \"user+fsf@my.domain\"))"
 :group 'gnus-various-unmunge)

(defcustom unmunge-addressee-sigfile-alist
      nil
      "*A list of pairs of email address regexps and signature filenames.

A list of dotted pairs, the first being a regexp with which the recipients
email address is matched, and the second a string, or a function or variable
returning a string, which is a readable signature file  address.  More general
regexps should go at the end.  The matching is done by
`unmunge-mail-address-function'.

For example:
((\"owen\" . nil)
 (\"ma.man.ac.uk\" . \"~/.sig-bland\")
 (\"gnu.org\" . \"user+fsf@my.domain\"))"
 :group 'gnus-various-unmunge)

(defcustom unmunge-sigfile-alist nil
      "*A list of pairs of newsgroup regexps and signature files.

A list of dotted pairs, the first being a regexp with which the newsgroup
name is matched, and the second a string or nil, or a function returning a
string or nil, which is a readable filename.  More general regexps
should go at the end. The matching is done by `unmunge-sigfile-function'.

For example
'((\"alt.binaries.senior-citizens\" . \"~/.signature.deviant\")
  (\"linux\" . unmunge-sigfile-linux)
  (\"alt.fan.warlord\" . nil))"
:group 'gnus-various-unmunge)


;;; FUNCTIONS
(defun unmunge-compare (str list &optional default)
  "Compare a string to an alist, returning a partner to a matching value.
`STR' is a string and `LIST' is an alist of the form
   ((string1 . val1) (string2 . val2) ... (stringn . valn)).
   `unmunge-compare' compares `STR' to the `stringi' in turn, returning
`vali' for the first match, and evals and returns `DEFAULT' or nil if
there are no matches."
  (if (not list) (eval default)
    (if (string-match (car (car list)) str)
	(cdr (car list))
      (unmunge-compare str (cdr list) default))))

(defun unmunge-address-function ()
  "Set 'user-mail-address' to something suitable.

See documentation for `unmunge-alist' and
`unmunge-addressee-address-alist'."
  (make-local-variable 'user-mail-address)
  (setq user-mail-address (unmunge-get-address)))

(defun unmunge-get-address ()
  "Return a string to be used as the From: Field in `message-mode'."
  (eval
   (if (mail-fetch-field "To")
       (unmunge-compare
	(unmunge-fetch-and-parse-field "To" unmunge-read-all-addresses)
	unmunge-addressee-address-alist
	;; Base default on gnus-newsgroup-name
	(if gnus-newsgroup-name
	    `(unmunge-compare
	      gnus-newsgroup-name unmunge-alist
	      ,(eval unmunge-mail-address))
	  'unmunge-mail-address))
     (unmunge-compare
      (unmunge-fetch-and-parse-field
       "Newsgroups" unmunge-read-all-groups)
      unmunge-alist 'unmunge-default-address))))



(defun unmunge-fetch-and-parse-field (fieldname all)
  "Read the field named FIELDNAME from message headers.
Truncates at the first comma if ALL is non-nil."
  (let ((string (mail-fetch-field fieldname)))
    (if all string
      (let ((subs (string-match "," string)))
	(if subs (substring string 0 subs) string)))))



(defun unmunge-sigfile-function ()
  "Set 'message-signature-file' to something suitable.

In particular, set it to the return value of  (unmunge-get-sigfile), and
make it local to that message buffer.\n
See documentation for `unmunge-signature-alist' and
`unmunge-addressee-sigfile-alist'."
  (make-local-variable 'message-signature-file)
  (setq message-signature-file (unmunge-get-sigfile)))

(defun unmunge-get-sigfile ()
  "Return the name of a file containing the signature to be appended."
  (eval ;; Since we may return a function from the alist.
   (if (mail-fetch-field "To")
       ;; Mail
       (unmunge-compare
	(unmunge-fetch-and-parse-field "To" unmunge-read-all-addresses)
	unmunge-addressee-sigfile-alist
	;; Base default on gnus-newsgroup-name
	(if gnus-newsgroup-name
	    '(unmunge-compare gnus-newsgroup-name unmunge-sigfile-alist
			      'unmunge-mail-sigfile)
	  unmunge-mail-sigfile))
     ;; Not mail
     (unmunge-compare
      (unmunge-fetch-and-parse-field "Newsgroups" unmunge-read-all-groups)
      unmunge-sigfile-alist unmunge-default-sigfile))))



;;; The stuff to reparse the To and Newsgroup lines in order to change your
;;  sig/address on posting.  Handy for mails.
(defun unmunge-postfix-signature ()
  "Scan the To: or Newsgroup: lines *on posting* and modify signature.

This typically occurs immediately prior to sending, by adding this function
to `message-send-hook'.
Asks for confirmation unless `unmunge-postfix-skip-confirm' is non-nil."
  ;;Bear in mind we could be narrowed when sent
  (save-excursion
    (let (new-sig)
      (widen)
      (setq new-sig (unmunge-get-sigfile))
      (if (not (equal message-signature-file new-sig))
	  ;;Check we really want this.  It is of dubious merit.
	  (if (or unmunge-postfix-skip-confirm
		  (yes-or-no-p
		   (concat "Replace present signature with"
			   (if new-sig
			       (concat " contents of " new-sig "? ")
			     " nothing? "))))
	      ;; Yes, go ahead
	      (progn
		(goto-char (point-max))
		(condition-case nil
		    (search-backward-regexp message-signature-separator)
		  (error
		   (message
		    "No signature found, appending new signature.")))
		(delete-region (point) (point-max))
		(setq message-signature-file new-sig)
		(message-insert-signature)))))))



(defun unmunge-postfix-address ()
  "Scan the To: or Newsgroup: lines *on posting* and modify From: address.

This typically occurs immediately prior to sending, by adding this function
to `message-send-hook'.
Asks for confirmation unless `unmunge-postfix-skip-confirm' is non-nil."
  ;;Bear in mind we could be narrowed when sent
  (save-excursion
    (let (new-address)
      (progn
	(widen)
	(setq new-address (unmunge-get-address))
	(if (not (equal user-mail-address new-address))
	    ;;Check we really want this.  It is of dubious merit.
	    (if (or
		 unmunge-postfix-skip-confirm
		 (yes-or-no-p
		  (concat "Replace present From: address ("
			  user-mail-address ") with " new-address "? ")))
		(setq user-mail-address new-address)))))))


(defvar unmunge-version "0.6.1" "Unmunge version number.")
(provide 'unmunge-general)
;;; unmunge-general.el ends here
