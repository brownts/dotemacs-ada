;;; package --- summary  -*- lexical-binding: t; -*-
;;; commentary:
;;; code:

;;;; Configuration

(defgroup init.el nil
  "Configuration options for init.el."
  :group 'emacs
  :prefix "init.el/")

(defcustom init.el/preferred-diagnostics-reporter 'flymake
  "Preferred diagnostics reporter."
  :type '(choice (const flymake)
                 (const flycheck))
  :group 'init.el)

(defcustom init.el/preferred-lsp-client 'lsp-mode
  "Preferred LSP client."
  :type '(choice (const lsp-mode)
                 (const eglot))
  :group 'init.el)

;;;; Custom

;; Don't pollute this file with custom settings
(setopt custom-file (locate-user-emacs-file "custom-settings.el"))
(load custom-file 'noerror)

;;;; use-package

(setopt use-package-always-ensure t)
(setopt use-package-always-defer t)

;;;; package.el

(use-package package
  :ensure nil ; built-in
  :config
  (add-to-list 'package-archives '("melpa"     . "https://melpa.org/packages/"))
  (add-to-list 'package-archives '("gnu-devel" . "https://elpa.gnu.org/devel/")))

;;;; Ada

(use-package ada-ts-mode
  :defines (org-src-lang-modes)
  :custom ((ada-ts-mode-grammar-install 'auto)
           (ada-ts-mode-indent-backend 'lsp)) ; Use LSP-based indenting
  :bind (:map ada-ts-mode-map
              (("C-c C-b" . ada-ts-mode-defun-comment-box)
               ("C-c C-o" . ada-ts-mode-find-other-file)
               ("C-c C-p" . ada-ts-mode-find-project-file)))
  :init
  (with-eval-after-load 'org-src
    (add-to-list 'org-src-lang-modes '("ada" . ada-ts))))

;;;; GNAT Project

(use-package gpr-ts-mode
  :defines (org-src-lang-modes)
  :custom (gpr-ts-mode-grammar-install 'auto)
  :init
  (with-eval-after-load 'org-src
    (add-to-list 'org-src-lang-modes '("gpr" . gpr-ts)))
  :hook (gpr-ts-mode . gpr-ts-auto-case-mode))

;;;; Completion

(use-package emacs
  :ensure nil ; built-in
  :init (setq completion-ignore-case t)
  :custom (tab-always-indent 'complete)) ; Complete when already indented

;;;;; Company

(use-package company
  :demand t
  :commands (global-company-mode)
  :functions (company-indent-or-complete-common)
  :bind
  ;; Allow Company to be triggered manually through the normal
  ;; `indent-for-tab-command' binding.  See the following link for
  ;; details: https://emacs.stackexchange.com/a/46792
  (:map company-mode-map
        (([remap indent-for-tab-command] . company-indent-or-complete-common)))
  ;; Use TAB instead of RET to complete
  (:map company-active-map
        (("RET"      . nil) ; remove from map
         ("<return>" . nil) ; remove from map
         ("TAB"      . company-complete-selection)
         ("<tab>"    . company-complete-selection)))
  :custom ((company-minimum-prefix-length 2)
           (company-icon-margin 3)
           (company-require-match nil)
           (company-tooltip-align-annotations t))
  :config (global-company-mode))

(use-package company-quickhelp
  :custom ((company-quickhelp-delay 0.0)
           ;; Workaround for https://debbugs.gnu.org/cgi/bugreport.cgi?bug=74807
           (company-quickhelp-use-propertized-text nil))
  :commands (company-quickhelp-local-mode)
  :hook (company-mode . company-quickhelp-local-mode))

;;;;; Minibuffer Completion

(use-package vertico
  :demand t
  :commands (vertico-mode)
  :config (vertico-mode))

;;;; Compile

(use-package compile
  :ensure nil ; built-in
  :custom (compilation-scroll-output t)
  :init
  (put 'compile-command 'safe-local-variable #'stringp))

;;;; Diagnostics

;;;;; Flycheck

(use-package flycheck
  :if (eq init.el/preferred-diagnostics-reporter 'flycheck)
  :functions (flycheck-overlay-errors-at
              flycheck-help-echo-all-error-messages)
  :preface
  (defun init.el/flycheck-errors-at-point (callback &rest _)
    (when-let ((diagnostics (and (bound-and-true-p flycheck-mode)
                                 (flycheck-overlay-errors-at (point)))))
      (funcall callback
               (flycheck-help-echo-all-error-messages
                diagnostics))))
  ;; Disable intrinsic display function, as Eldoc will be used instead.
  :custom (flycheck-display-errors-function nil)
  :init
  ;; Configure Flycheck to display diagnostics via Eldoc
  (add-hook 'eldoc-documentation-functions
            #'init.el/flycheck-errors-at-point)
  :hook (prog-mode . flycheck-mode))

(use-package flycheck-eglot
  :if (eq init.el/preferred-diagnostics-reporter 'flycheck)
  :custom (flycheck-eglot-exclusive nil)
  :hook (eglot-managed-mode . flycheck-eglot-mode))

(use-package consult-flycheck
  :if (eq init.el/preferred-diagnostics-reporter 'flycheck)
  :bind ("M-g M-d" . consult-flycheck))

;;;;; Flymake

(use-package flymake
  :ensure nil ; built-in
  :if (eq init.el/preferred-diagnostics-reporter 'flymake)
  :hook (prog-mode . flymake-mode))

(use-package consult-flymake
  :ensure consult ; part of consult
  :if (eq init.el/preferred-diagnostics-reporter 'flymake)
  :bind ("M-g M-d" . consult-flymake))

;;;; Eglot

(use-package eglot
  :ensure nil ; built-in
  :pin gnu-devel
  :if (eq init.el/preferred-lsp-client 'eglot)
  :preface
  ;; Workaround for https://github.com/AdaCore/ada_language_server/issues/1204
  (defun init.el/fix-eol/eglot--format-markup (value)
    (let ((strings (list value)))
      (dolist (eol '("\r\n" "\n" "\r"))
        (setq strings
              (flatten-list (mapcar (lambda (value)
                                      (split-string value eol))
                                    strings))))
      (string-join strings "\n")))
  :init
  ;; Force upgrade to ELPA version for Emacs 29
  (unless (or (> emacs-major-version 29)
              (member 'eglot package-selected-packages))
    (package-install (cadr (assoc 'eglot package-archive-contents))))
  (advice-add 'eglot--format-markup
              :filter-return #'init.el/fix-eol/eglot--format-markup)
  :hook ((ada-ts-mode gpr-ts-mode) . eglot-ensure)
  :custom (eglot-extend-to-xref t) ; Consider external refs, part of project.
  :config
  ;; Let major mode control Imenu
  (add-to-list 'eglot-stay-out-of 'imenu)
  ;; Add `lsp-mode' language server installation location to
  ;; `exec-path' so Eglot can find it.
  (add-to-list 'exec-path
               (expand-file-name
                (let ((os-dir (cond ((eq system-type 'gnu/linux)  "linux")
                                    ((eq system-type 'windows-nt) "win32")
                                    ((eq system-type 'darwin)     "darwin")))
                      (arch-dir (cond ((string-prefix-p "x86_64-"  system-configuration) "x64")
                                      ((string-prefix-p "aarch64-" system-configuration) "arm64"))))
                  (string-join `(".cache/lsp/ada-ls" ,arch-dir ,os-dir) "/"))
                user-emacs-directory)))

;;;; Emacs

(use-package emacs
  :ensure nil ; built-in
  :init
  ;; Recommended settings when using LSP
  :custom ((gc-cons-threshold 100000000)             ; 100MB
           (read-process-output-max (* 1024 1024)))) ; 1MB

;;;; Files

(use-package files
  :ensure nil ; built-in
  :defer t
  :custom ((make-backup-files nil)
           (auto-save-default nil)
           (create-lockfiles nil)))

;;;; Imenu

(use-package imenu
  :ensure nil ; built-in
  :custom (imenu-auto-rescan t)
  :hook ((ada-ts-mode gpr-ts-mode) . imenu-add-menubar-index))

;;;; lsp-mode

(use-package lsp-mode
  :if (eq init.el/preferred-lsp-client 'lsp-mode)
  :preface
  ;; Workaround for https://github.com/AdaCore/ada_language_server/issues/1204
  (defun init.el/fix-eol/lsp--render-string (args)
    (let ((strings (list (car args))))
      (dolist (eol '("\r\n" "\n" "\r"))
        (setq strings
              (flatten-list (mapcar (lambda (value)
                                      (split-string value eol))
                                    strings))))
      (cons (string-join strings "\n") (cdr args))))
  (defun init.el/lsp-mode ()
    ;; Delay start until after initialization of local variables as they may
    ;; contain `lsp-mode' configuration variables.
    (declare-function lsp "lsp-mode")
    (add-hook 'hack-local-variables-hook #'lsp t 'local))
  :init
  (advice-add 'lsp--render-string
              :filter-args #'init.el/fix-eol/lsp--render-string)
  :custom ((lsp-auto-guess-root t)
           (lsp-diagnostics-provider
            (intern (concat ":" (symbol-name init.el/preferred-diagnostics-reporter))))
           (lsp-enable-indentation nil) ; Let major mode control indentation
           (lsp-enable-on-type-formatting nil) ; Interferes with Emacs indenting
           (lsp-headerline-breadcrumb-enable nil)
           (lsp-keymap-prefix "C-c l")
           (lsp-semantic-tokens-enable t)
           (lsp-enable-imenu nil)) ; Let major mode control Imenu
  ;; Add mapping for `lsp-mode' "xref" functions
  :bind (:map lsp-mode-map (("M-." . lsp-find-definition)
                            ("M-?" . lsp-find-references)))
  :custom-face
  (lsp-face-semhl-number ((t (:inherit font-lock-number-face))))
  :hook ((ada-ts-mode gpr-ts-mode) . init.el/lsp-mode))

;;;; Markdown

(use-package markdown-mode
  :config
  ;; Some LSP servers use "plaintext" in code fences (i.e., Ada LS), but
  ;; `markdown-mode' (used by Eglot) doesn't provide a mode mapping and ends up
  ;; using markdown, which can be problematic if markdown syntax is found in the
  ;; text.  Therefore, we add a specific mapping for "plaintext" to text mode.
  (add-to-list 'markdown-code-lang-modes '("plaintext" . text-mode)))

;;;; Project

(use-package project
  :ensure nil ; built-in
  :custom (project-vc-extra-root-markers
           '("adainclude" "alire.toml" ".project" ".projectile" ".vscode")))

;;;; Which Function

(use-package which-func
  :ensure nil ; built-in
  :demand t
  :config (which-function-mode))

;;;; Xref

(use-package xref
  :ensure nil ; built-in
  :preface
  (defun init.el/fix-point/xref-find-definitions-at-mouse (event)
    (interactive "e")
    (mouse-set-point event))
  :init
  ;; Workaround for https://debbugs.gnu.org/cgi/bugreport.cgi?bug=65578
  (when (< emacs-major-version 30)
    (advice-add 'xref-find-definitions-at-mouse
                :before #'init.el/fix-point/xref-find-definitions-at-mouse))
  :bind (("C-<mouse-1>" . #'ignore) ; Prevent "undefined" message on mouse up
         ("C-<down-mouse-1>" . #'xref-find-definitions-at-mouse)))

;;;; YASnippet

(use-package yasnippet
  ;; LSP snippets are handled via YASnippet.
  :hook ((eglot-managed-mode lsp-mode) . yas-minor-mode))

(use-package gpr-yasnippets)

;;; init.el ends here
