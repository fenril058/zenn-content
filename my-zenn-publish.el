;;; my-zenn-publish.el --- Export Markdown for Zenn.dev -*- lexical-binding: t; -*-

;;; Commentary:

;; publish
;; emacs --batch --no-init-file --load my-zenn-publish.el --eval "(org-publish "zenn")"
;;
;; force publish
;; emacs --batch --no-init-file --load my-zenn-publish.el --eval "(org-publish "zenn" t)"

;;; Code:

(setq package-enable-at-startup nil
      package-quickstart nil
      make-backup-files nil
      auto-save-default nil
      auto-save-list-file-prefix nil
      create-lockfiles nil)

(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8)

(require 'ox-publish)
(require 'ox-yazenn-article)
(require 'ox-yazenn-book)

(defcustom my-zenn-target-directory "~/ghq/github.com/fenril058/zenn-content/"
  "Zenn CLIが参照するディレクトリ"
  :type 'string
  :group 'org-export-yazenn)

(defcustom my-zenn-working-directory (file-name-concat my-zenn-target-directory "org/")
  "Org原稿があるディレクトリ"
  :type 'string
  :group 'org-export-yazenn)

(defcustom org-yazenn-zenndev-username "ril"
  "Zenn.devのユーザーID"
  :type 'string
  :group 'org-export-yazenn)

(setq org-publish-timestamp-directory (file-name-concat my-zenn-working-directory ".org-timestamps/"))

;; 常にキャッシュを全削除したから生成するなら、コメントアウト
;; (org-publish-remove-all-timestamps)

;; nil にするとtimestampをチェックせずに生成する
;; (setq org-publish-use-timestamps-flag nil)

(setq org-publish-project-alist
      `(("zenn" :components ("articles" "books"))
        ("articles"
         :base-directory "./org/articles"
         :recursive nil
         :publishing-function org-yazenn-article-publish-to-md
         :publishing-directory ,(file-name-concat my-zenn-target-directory "articles")
         :with-author nil
         :with-creater nil
         :with-toc nil
         :section-numbers nil
         :yazenn-with-published nil)
        ("books"
         :base-directory "./org/book"
         :recursive nil
         :publishing-function org-yazenn-book-publish-to-zenn-book
         :publishing-directory ,(file-name-concat my-zenn-target-directory "books")
         :with-author nil
         :with-creator nil
         :with-toc nil
         :section-numbers nil
         :yazenn-with-published nil)))

;; (org-publish-all t)
;; (message "Build complete!")

(provide 'my-zenn-publish)
;;; my-zenn-publish.el ends here
