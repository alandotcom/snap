(local snap (require :snap))
(local tbl (require :snap.common.tbl))

(fn report-error [error]
  (vim.notify (.. "There was an error when calling LSP: " error.message) vim.log.levels.ERROR))

(fn lsp-buf-request [bufnr action params on-value on-error]
  (vim.lsp.buf_request bufnr action params
    (fn [error result context]
      (if error
        (on-error error)
        (let [client (vim.lsp.get_client_by_id context.client_id)
              results (if (vim.tbl_islist result) result [result])]
          (on-value {: bufnr : results :offset_encoding client.offset_encoding}))))))

(fn lsp-producer [bufnr action params tranformer]
  (local (response error) (snap.async (partial lsp-buf-request bufnr action params)))
  (when error (snap.sync #(report-error error)))
  (snap.sync (partial tranformer (or response {}))))

(fn get-bufnr [winnr]
  (snap.sync #(vim.api.nvim_win_get_buf winnr)))

(fn get-params [winnr]
  (snap.sync #(vim.lsp.util.make_position_params winnr)))

;; Transformers take a response and return results
;; they are executed inside snap.sync
(local transformers {})

(fn transformers.locations [{: offset_encoding : results}]
  (vim.tbl_map
    #(snap.with_metas $1.filename (tbl.merge $1 {: offset_encoding}))
    (vim.lsp.util.locations_to_items results offset_encoding)))

(fn transformers.symbols [{: bufnr : results}]
  (vim.tbl_map
    #(snap.with_metas $1.text $1)
    (vim.lsp.util.symbols_to_items results bufnr)))

(fn locations [action {: winnr}]
  (lsp-producer
    (get-bufnr winnr)
    action
    (get-params winnr)
    transformers.locations))

(local definitions #(locations "textDocument/definition" $1))
(local implementations #(locations "textDocument/implementation" $1))
(local type_definitions #(locations "textDocument/typeDefinition" $1))

(fn references [{: winnr}]
  (lsp-producer
    (get-bufnr winnr)
    "textDocument/references"
    (tbl.merge (get-params winnr) {:context {:includeDeclaration true}})
    transformers.locations))

(fn symbols [{: winnr}]
  (lsp-producer
    (get-bufnr winnr)
    "textDocument/documentSymbol"
    (get-params winnr)
    transformers.symbols))


(fn workspaceSymbols [{: winnr}]
  (lsp-producer
    (get-bufnr winnr)
    "workspace/symbol"
    (get-params winnr)
    transformers.symbols))

{: definitions
 : implementations
 : type_definitions
 : references
 : symbols
 : workspaceSymbols}
