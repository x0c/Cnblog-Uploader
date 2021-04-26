import sys
import xmlrpc.client

config = {
    "blog_url": "https://rpc.cnblogs.com/metaweblog/[blog_id]",
    "blog_id": "[blog_id]",
    "username": "[用户名]",
    "password": "[密码]",
}

blog_url = config["blog_url"].strip()
server = xmlrpc.client.ServerProxy(blog_url)


def upload(file_path, title, category, publish=False):
    with open(file_path, encoding='utf-8') as f:
        content = f.read()
        post = dict(description=content, title=title,
                    categories=['[Markdown]', '{}'.format(category)])
        article_id = server.metaWeblog.newPost(
            config["blog_id"], config["username"], config["password"], post, publish)
        article_url = "https://www.cnblogs.com/{}/p/{}.html".format(
            config["blog_id"], article_id)
        return article_url


def get_categories():
    cate_list = server.metaWeblog.getCategories(
        config["blog_id"], config["username"], config["password"])
    result = ",".join([cate["title"] for cate in cate_list])
    return(result)


if __name__ == "__main__":
    result = "-1"
    try:
        args = sys.argv[1:]
        if args[0] == "-c":
            result = get_categories()
        else:
            file_path = args[0]
            title = args[1]
            category = args[2]
            pub = args[3]
            publish = True if pub == "1" else False
            result = upload(file_path, title, category, publish)
    except IndexError:
        result = "-1"
    finally:
        print(result)
        exit
