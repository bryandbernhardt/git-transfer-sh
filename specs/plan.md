# Plano técnico

## Contexto
Implementa a especificação do script, respeitando a constituição do projeto. O objetivo é criar um CLI de anonimização de histórico do Git.

## Arquitetura
- **Executável:** Apenas um arquivo `.sh` consolidado para facilitar a distribuição e execução sem dependências complexas.
- **Testes:** Estrutura de pastas dedicada (ex: diretório `spec/`) estritamente para os testes unitários do ShellSpec, não afetando o executável final em produção.
- Lógica interna isolada em funções com responsabilidades únicas e bem documentadas via comentários.

## Decisões
- **D-01 (Armazenamento de Estado):** Para atender aos RF-04 e RF-05 sem ferir a Constituição (script puro), o sistema armazenará os hashes dos commits originais em um arquivo de texto plano oculto (dotfile) sem extensão chamado `.processed_commits` na raiz do novo repositório gerado.

## Modelo de dados
- **Controle de Hashes (`.processed_commits`):** Arquivo de texto simples de coluna única, contendo apenas o SHA-1 original em cada linha (garante alta performance para o comando `grep` e fácil manipulação pelo programador).
- **Arquivos Genéricos:** Para preservar os pesos por bytes usados pelo cartão Top Languages do GitHub Readme Stats, manter um arquivo por extensão na raiz com nome `file.<ext>` (ou `file` sem extensão). Para cada snapshot de origem, somar os tamanhos em bytes dos blobs por extensão via metadados de `git ls-tree -r -l`. Gerar exatamente essa quantidade de caracteres ASCII alfanuméricos pseudoaleatórios (um byte por caractere), sem ler ou copiar conteúdo dos blobs. Usar o hash da árvore mais a extensão como seed para que snapshots diferentes produzam conteúdo reproduzível e árvores de destino distintas; extensões ausentes são removidas e as novas criadas.

## Contratos
- O sistema recebe *inputs* exclusivamente via prompt interativo no terminal no momento da execução (e-mail corporativo, e-mail pessoal).
- O sistema entrega como *output* uma nova pasta no sistema de arquivos contendo um repositório `.git` fechado e pronto para o usuário realizar um `git push` manual.
- Antes de cada commit correspondente, sincronizar todos os arquivos genéricos com os totais por extensão do snapshot daquele commit, não somente com os caminhos alterados no commit. Commits vazios sem mudança de árvore podem resultar em commits de destino vazios.

## Riscos
- **Compatibilidade POSIX:** Diferenças entre GNU Coreutils (padrão Linux/Windows Git Bash) e BSD Coreutils (padrão MacOS), principalmente no tratamento e formatação de datas via comando `date`. Solução: mitigar criando abstrações compatíveis com ambas as plataformas ou forçando o uso de POSIX `date`.
- **Nomes de arquivos com espaços e caracteres especiais:** O loop do Bash pode quebrar ao processar commits originais que adicionaram/removeram arquivos com espaços no nome. Solução: utilizar separadores adequados (como `IFS` ou arrays) no momento da extração de logs do Git.