;;; early-init.el --- summary  -*- lexical-binding: t; -*-
;;; commentary:
;;; code:

;; (setq init.el/completion-lsp-allow-trigger-chars nil)
;; (setq init.el/completion-lsp-disallowed-categories nil)
;; (setq init.el/completion-minimum-prefix-length 3)
;; (setq init.el/completion-quick-access t)
;; (setq init.el/preferred-completion-ui 'company)
;; (setq init.el/preferred-diagnostics-reporter 'flycheck)
;; (setq init.el/preferred-documentation-ui 'echo)
;; (setq init.el/preferred-lsp-client 'eglot)
;; (setq init.el/lsp-mode-specific-settings nil)
;; (setq ada-ts-mode-indent-backend 'lsp)

(setq-default indent-tabs-mode nil)

;; Ignore native compilation warnings (usually a nuisance)
(setopt native-comp-async-report-warnings-errors 'silent)

;; Byte-compiled files may not be compatible between different Emacs
;; versions, and since (M)ELPA installed packages are compiled in
;; their own sub-directories within `package-user-dir', use a separate
;; `package-user-dir' for different versions of Emacs.
(setq package-user-dir
      (expand-file-name
       (format "elpa/%s.%s" emacs-major-version emacs-minor-version)
       user-emacs-directory))

(provide 'early-init)

;;; early-init.el ends here
