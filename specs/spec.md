# Documento de Especificação: Git Transfer SH

## Problema 
Programadores que utilizam plataformas e contas corporativas não conseguem manter seus gráficos de contribuição e estatísticas de linguagens atualizados em seus perfis pessoais do GitHub, pois o código da empresa não pode ser misturado com repositórios pessoais.

## Objetivo 
Fornecer uma ferramenta de linha de comando (CLI) que extraia os metadados e a volumetria dos commits de um desenvolvedor em um repositório corporativo, gerando um novo repositório local e anonimizado. Este novo repositório espelhará o histórico (datas e linguagens) para ser enviado ao GitHub pessoal. A volumetria por extensão deve preservar os bytes considerados pelo cartão Top Languages do GitHub Readme Stats, sem vazar código original ou mensagens sensíveis.

## Usuários 
- **Programador:** Executa o script via terminal em sua própria máquina.

## Histórias de Usuário
- **HU-01:** Como programador, quero rodar o script de dentro da pasta do repositório da empresa, informando meu e-mail atual (origem) e meu e-mail pessoal (destino), para que a ferramenta saiba quais commits deve espelhar.
- **HU-02:** Como programador, quero que o novo repositório gerado possua apenas arquivos genéricos, um por extensão e na raiz, refletindo o tamanho em bytes dos blobs de cada extensão no snapshot de cada commit de origem. O conteúdo deve ser composto por caracteres ASCII alfanuméricos pseudoaleatórios e ter exatamente a soma dos bytes originais daquela extensão, sem copiar o código. As mensagens originais devem ser substituídas por mensagens genéricas, preservando as datas exatas, sem copiar nomes de arquivos ou estrutura de pastas.
- **HU-03:** Como programador, quero executar essa ferramenta como um arquivo único em meu sistema operacional, sem precisar instalar bibliotecas extras ou pacotes (assumindo que eu já tenha o Git instalado localmente).

## Requisitos Funcionais 
- **RF-01:** O script deve ser executado no diretório atual do repositório corporativo e solicitar/receber os e-mails de origem e destino.
- **RF-02:** O script deve criar uma nova pasta na máquina do usuário para inicializar o repositório espelho.
- **RF-03:** Para cada commit não merge do autor na origem, o script deve gerar um commit correspondente no destino com a data original (timestamp), e-mail de destino, arquivos genéricos na raiz e uma **mensagem de commit genérica** (ex: "Commit espelhado"). Para cada snapshot, deve somar os tamanhos em bytes de todos os blobs agrupados pela extensão e gerar um arquivo cujo conteúdo ASCII alfanumérico pseudoaleatório tenha exatamente esse total de bytes. Extensões ausentes devem ser removidas e extensões novas criadas. Commits vazios podem permanecer vazios. A mensagem original do commit **não** deve ser copiada.
- **RF-04:** O sistema deve registrar o *hash identificador (SHA-1)* de cada commit processado em um arquivo local de controle (ex: `.commits_copiados`), para evitar duplicações em execuções futuras.
- **RF-05:** Se o usuário manipular o arquivo de controle e remover o *hash* de um commit, o sistema deve ser capaz de reprocessar esse commit na próxima execução.
- **RF-06:** O script deve exibir no terminal o progresso da operação: total de commits encontrados, quantos já estavam copiados e quantos estão sendo processados agora.
- **RF-07:** Para preservar a volumetria usada pelo cartão Top Languages do GitHub Readme Stats, o script deve criar um arquivo genérico por extensão presente no snapshot. O tamanho do arquivo deve ser igual à soma, em bytes, dos blobs de origem daquela extensão no mesmo snapshot. O conteúdo deve usar caracteres ASCII alfanuméricos pseudoaleatórios de um byte cada, sem incluir conteúdo original. O arquivo deve ser editado em cada commit selecionado para corresponder ao snapshot daquele commit.
- **RF-08:** O script deve criar todos os arquivos na raiz do repositório clone, sem copiar a estrutura de arquivos e pastas do projeto de origem.

## Regras de Negócio 
- **RN-01:** O arquivo de controle deve armazenar apenas o *hash (SHA-1)* do commit original. Sob nenhuma hipótese o código-fonte original ou a mensagem original do commit devem ser lidos para armazenamento ou replicados no destino.
- **RN-02:** O sistema é responsável apenas por gerar o repositório localmente. O *push* (envio) para a URL pública no GitHub é de total responsabilidade do usuário, de forma manual.

## Casos de Borda (Mapeados para Testes)
- **Merge Commits:** Commits de merge geralmente não possuem alterações diretas de código do usuário, apenas unem branches. O script deve saber ignorá-los ou tratá-los para não quebrar a geração dos arquivos falsos.
- **Commits Vazios:** Commits gerados com a flag `--allow-empty` devem ser replicados como vazios no destino, usando também uma mensagem genérica.

## Fora de Escopo 
- Autenticação com APIs do GitHub, GitLab ou Bitbucket.
- Envio automatizado (*push*) para servidores remotos.
- Instalação de um cliente Git na máquina do usuário.

## Critérios de Aceite 
1. Ao executar o script pela segunda vez consecutiva no mesmo repositório, o terminal deve exibir a mensagem de que não possui commits novos e encerrar sem criar dados duplicados.
2. O histórico do repositório espelho gerado (`git log`) deve exibir as datas passadas exatamente iguais às do repositório da empresa.
3. Ao inspecionar os arquivos gerados e o histórico de commits (`git log`) no repositório espelho, nenhuma variável, lógica, texto do código corporativo ou **mensagem original de commit** deve estar presente. O conteúdo dos arquivos deve corresponder às extensões alteradas no commit original.
4. O repositório final gerado deve permitir que o usuário faça `git remote add` e `git push` manualmente sem causar conflitos estruturais.
5. Cada commit não vazio do autor que não seja merge deve aparecer no histórico do destino com uma alteração genérica correspondente; commits consecutivos da mesma extensão não podem resultar em árvores idênticas.
6. Para cada commit espelhado, o tamanho de cada arquivo genérico deve ser exatamente igual à soma em bytes dos blobs da mesma extensão no snapshot de origem correspondente. Arquivos de zero bytes devem continuar com zero bytes.