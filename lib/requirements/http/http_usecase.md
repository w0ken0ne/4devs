# HTTP

## Sucesso

1. Request com verbo válido (post)
2. Passar nos headers o content type json
3. Ok - 200 e resposta com dados
4. No content -204 e resposta sem dados

## Erros

1. Bad request - 400
2. Unauthorized - 401
3. Forbidden - 403
4. Not Found - 404
5. Internal Server Error - 500

## Exceção - Status code diferente dos citados acima

1. Internal Server Error - 500

## Exceção - Http request deu alguma exceção

1. Internal Server Error - 500

## Exceção - Verbo http inválido

1. Internal Server Error - 500
