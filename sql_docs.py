import sql_docs_functions as fuction

def sql_docs(sql_file: str) -> str:
    sql_str = fuction.read_sql_file(sql_file)
    summary_doc = fuction.summary(sql_str)
    related_doc = fuction.related(sql_str)
    source_doc = fuction.sources(sql_str) 
    products_doc = fuction.products(sql_str)
    versions_doc = fuction.versions(sql_str)
    comments_doc = fuction.comments(sql_str)

    sql_doc_html = fuction.html(summary_doc, related_doc, source_doc, products_doc, versions_doc, comments_doc)
    return sql_doc_html