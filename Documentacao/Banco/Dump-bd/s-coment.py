import re

# Tente abrir o arquivo com 'utf-8' primeiro
try:
    with open('indoorroutes_dump_add_terreo_2_3_andares.sql', 'r', encoding='utf-8') as file:
        content = file.read()
except UnicodeDecodeError:
    # Se falhar, tente com 'latin-1'
    with open('indoorroutes_dump_add_terreo_2_3_andares.sql', 'r', encoding='latin-1') as file:
        content = file.read()

# Remover comentários de bloco (/* */)
content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)

# Remover comentários de linha (-- até o final da linha)
content = re.sub(r'--.*', '', content)

# Remover linhas vazias ou compostas apenas por espaços em branco
# Dividir o conteúdo em linhas
lines = content.splitlines()

# Filtrar as linhas não vazias
non_empty_lines = [line for line in lines if line.strip() != '']

# Juntar as linhas novamente com quebras de linha
content_no_empty_lines = '\n'.join(non_empty_lines)

# Escrever o conteúdo sem comentários e sem linhas vazias em um novo arquivo
with open('indoorroutes_dump_sem_comentarios.sql', 'w', encoding='utf-8') as file:
    file.write(content_no_empty_lines)
