;;; pasteit.el --- 

;; Copyright (C) 2013 Free Software Foundation, Inc.
;;
;; Author: Taras Iagniuk <mrtaryk@gmail.com>
;; Maintainer: Taras Iagniuk <mrtaryk@gmail.com>
;; Created: 02 Jul 2013
;; Version: 0.01
;; Keywords

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
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;; Dependencies:
;;
;; - json package ( available from ELPA and easy to install.
;; `M-x install-package` and type `json` )

;; Installation:
;;
;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'pasteit)
;;   (setq spinal-tap-code-mosh-url "http://spinal-tap-mode-mosh/")
;;   (setq spinal-tap-code-mosh-irc-channels '("channel1" "channel2"))
;;
;; You can also load `pasteit.el` directly
;;   (load-file "path/to/pasteit.el")
;;

;; Functions:
;;
;; M-x pasteit-region
;;   to send a selected region to Spinal:Tap:Mode:Mosh
;;
;; M-x pasteit-buffer
;;   to send whole buffer to Spinal:Tap:Mode:Mosh
;;
;; M-x pasteit-region-irc
;;   to send a selected region to Spinal:Tap:Mode:Mosh and notify people via IRC
;;
;; M-x pasteit-buffer-irc
;;   to send a whole buffer to Spinal:Tap:Mode:Mosh and notify people via IRC
;;

;; Note:
;; All functions ask for a title. If you leave it empty, filename will be used
;; as a title

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'url)
(require 'url-http)
(require 'json)

(defconst pasteit-version "0.01")

;; Customs

(defcustom spinal-tap-code-mosh-url "http://localhost/"
  "Spinal:Tap:Mode:Mosh server url"
  :group 'pasteit)

(defcustom spinal-tap-code-mosh-irc-channels '("channel")
  "IRC channels to notify"
  :group 'pasteit)

(defun http-post (url args)
  "Send ARGS to URL as a POST request."
  (let ((url-request-method "POST")
        (url-request-extra-headers
         '(("Content-Type" .
            "application/x-www-form-urlencoded; charset=UTF-8")))
        (url-request-data
         (mapconcat (lambda (arg)
                      (concat (url-hexify-string (car arg))
                              "="
                              (url-hexify-string (cdr arg))))
                    args
                    "&")))
    (with-current-buffer (url-retrieve-synchronously url)
      (if (= 200 url-http-response-status)
          (progn
            ;; status
            (setq status url-http-response-status)
            ;; return the header and the data separately
            (goto-char (point-min))
            (if (search-forward-regexp "^$" nil t)
                (setq header (buffer-substring (point-min) (point))
                      data   (buffer-substring (1+ (point)) (point-max)))
              ;; unexpected situation, return the whole buffer
              (setq data (buffer-string)))
            data)
        (error "Something went wrong. Status %d"
                url-http-response-status)))))

(defun ask-for-a-title ()
  (let ((title (read-from-minibuffer "Title: ")))
    (if (string= "" title) (buffer-file-name) title)))

(defun get-syntax ()
  (let ((mode (with-current-buffer (current-buffer) major-mode)))
    (cond ((or (eq mode 'cperl-mode)
               (eq mode 'perl-mode)
               (eq mode 'pod-mode)
               (eq mode 'tt-mode)) "perl")
          ((or (eq mode 'js-mode)
               (eq mode 'js2-mode)) "js")
          ((eq mode 'shell-script-mode) "bash")
          ((eq mode 'css-mode) "bash")
          ((eq mode 'diff-mode) "diff")
          ((eq mode 'php-mode) "php")
          ((eq mode 'python-mode) "python")
          ((eq mode 'ruby-mode) "ruby")
          ((eq mode 'sql-mode) "sql")
          ((or (eq mode 'xml-mode)
               (eq mode 'nxml-mode)) "xml")
          ((or (eq mode 'html-mode)
               (eq mode 'nxml-web-mode)) "html")
          (t "plain"))))

(defun pasteit (code)
  (http-post (concat spinal-tap-code-mosh-url "mosh")
             `(("subject" . ,(ask-for-a-title)) ;; buffer name as a title
               ("data" . ,code)                 ;; selected code
               ("poster" . ,(getenv "USER"))    ;; acting on behalf of $USER
               ("syntax" . ,(get-syntax)))))    ;; buffer's major mode

(defun message-mosh-url (mosh-data)
  (message
   (concat spinal-tap-code-mosh-url
           (cdr (assoc 'id mosh-data)))))

(defun notify-via-irc (channels mosh-data)
  (dolist (channel spinal-tap-code-mosh-irc-channels)
        (http-post (concat spinal-tap-code-mosh-url "irc")
                   ;; TODO ability to choose IRC channels
                   `(("channel" . ,channel) ;; hardcoded
                     ("mosh" . ,(json-encode mosh-data))))
      (message-mosh-url mosh-data)))

(defun pasteit-region (start end)
  "Just send a selected region to Spinal:Tap:Mode:Mosh"
  (interactive "*r")
  (let* ((code (buffer-substring start end))
         (mosh-data (cdar (json-read-from-string (pasteit code)))))
    (message-mosh-url mosh-data)
    mosh-data))

(defun pasteit-buffer ()
  "Just a send whole buffer to Spinal:Tap:Mode:Mosh"
  (interactive)
  (pasteit-region (point-min) (point-max)))

(defun pasteit-region-irc (start end)
  "Send a selected region to Spinal:Tap:Mode:Mosh and notify people via IRC"
  (interactive "*r")
  (let ((mosh-data (pasteit-region start end)))
    (notify-via-irc spinal-tap-code-mosh-irc-channels mosh-data)))
 
(defun pasteit-buffer-irc ()
  "Send a whole buffer to Spinal:Tap:Mode:Mosh and notify people via IRC"
  (interactive)
  (pasteit-region-irc (point-min) (point-max)))

(provide 'pasteit)
;;; pasteit.el ends here
