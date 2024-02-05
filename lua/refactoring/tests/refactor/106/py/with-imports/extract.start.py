import json

if __name__ == "main":
    bad_doc_ids = []

    with open("./some/path/full_bad.jsonl", 'r', encoding='utf-8') as f:
        while True:
            id = f.readline().strip().strip('"')
            if not id:
                break
            bad_doc_ids.append(id)

    bad_docs = []
    with open("./some/path/full.jsonl", 'r', encoding='utf-8') as f:
        while True:
            line = f.readline()
            if not line:
                break
            doc = json.loads(line)

            if doc['id'] in bad_doc_ids:
                bad_docs.append(id)
