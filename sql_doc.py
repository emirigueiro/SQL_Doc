import sql_doc_functions as fuctions

def sql_doc(sql_file: str) -> str:
    sql_str = fuctions.read_sql_file(sql_file)
    summary_doc = fuctions.summary(sql_str)
    related_doc = fuctions.related(sql_str)
    source_doc = fuctions.sources(sql_str) 
    products_doc = fuctions.products(sql_str)
    versions_doc = fuctions.versions(sql_str)
    comments_doc = fuctions.comments(sql_str)

    sql_doc_html = fuctions.html(summary_doc, related_doc, source_doc, products_doc, versions_doc, comments_doc)
    return sql_doc_html