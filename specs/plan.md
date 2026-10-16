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
- **Arquivos Genéricos:** Textos estáticos (ex: "Lorem Ipsum") que substituirão o código fonte corporativo, mantendo apenas a extensão do arquivo (ex: `.js`, `.py`).

## Contratos
- O sistema recebe *inputs* exclusivamente via prompt interativo no terminal no momento da execução (e-mail corporativo, e-mail pessoal).
- O sistema entrega como *output* uma nova pasta no sistema de arquivos contendo um repositório `.git` fechado e pronto para o usuário realizar um `git push` manual.

## Riscos
- **Compatibilidade POSIX:** Diferenças entre GNU Coreutils (padrão Linux/Windows Git Bash) e BSD Coreutils (padrão MacOS), principalmente no tratamento e formatação de datas via comando `date`. Solução: mitigar criando abstrações compatíveis com ambas as plataformas ou forçando o uso de POSIX `date`.
- **Nomes de arquivos com espaços e caracteres especiais:** O loop do Bash pode quebrar ao processar commits originais que adicionaram/removeram arquivos com espaços no nome. Solução: utilizar separadores adequados (como `IFS` ou arrays) no momento da extração de logs do Git.