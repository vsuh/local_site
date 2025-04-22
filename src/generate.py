import jinja2
import json
import os

def generate_html(template_path, json_data_path, output_path):
    env = jinja2.Environment(loader=jinja2.FileSystemLoader(os.path.dirname(template_path)))
    template = env.get_template(os.path.basename(template_path))

    with open(json_data_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    rendered_html = template.render(data)

    with open(output_path, 'w', encoding='utf-8') as outfile:
        outfile.write(rendered_html)


if __name__ == "__main__":
    template_path = os.path.join(os.getcwd(), 'src', 'index.tpl')
    json_data_path = os.path.join(os.getcwd(), 'src', 'site.json')
    output_path = os.path.join(os.getcwd(), 'index.html')
    generate_html(template_path, json_data_path, output_path)
