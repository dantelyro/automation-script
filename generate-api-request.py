import re
import os

input_file = "routes.ts"
output_folder = "./api"

with open(input_file, "r") as file:
  content = file.read()

# Extract endpoint information using regex
endpoints = re.findall(r"app\.(\w+)\(\s*'(\S+)',(?:\s*([^\s,]+)\s*,)?\s*(\w+)\)", content)

for method, path, middleware, controller in endpoints:
  function_name = f'{controller}'

  imported_file = f'./controllers/{controller}.ts'

  with open(imported_file, 'r') as file:
    content = file.read()

  pattern = r'\b(\w+): z\.(\w+)\(\)'

  # Find all matches using re.findall
  matches = re.findall(pattern, content)

  # Iterate through the matches and create JSDoc comments
  jsdoc_comments = "/**\n"
  jsdoc_comments += f" * @typedef {{Object}} Body,\n"
  for field, type_name in matches:
    jsdoc_comments += f" * @property {{{type_name}}} {field},\n"
  jsdoc_comments += " */"

  new_line_space = '\n '

  api_function = f"""
import {{ api }} from 'boot/axios'
import {{ throwError }} from './axios-catch.js'

{jsdoc_comments}

/**
 *
 * @param {{{{body: Body, params: Params}}}} request{f'{new_line_space}* @param {{string}} token' if middleware else ''}
 * @returns
 */
export async function {function_name} (request{', token' if middleware else ''}) {{
  /** @type {{import('axios').AxiosRequestConfig}} */
  const axiosConfig = {{
    url: '{path}',
    method: '{method.upper()}',
    data: request?.body,
    params: request?.params{f''',
    headers: {{
      Authorization: `Bearer ${{token}}`
    }}''' if middleware else ''}
  }}

  try {{
    const response = await api(axiosConfig)
    return response.data
  }} catch (error) {{
    throwError(error)
  }}
}}
"""

  if not os.path.exists(output_folder):
    os.mkdir(output_folder)

  file_path = os.path.join(output_folder, f'{controller}.js')

  with open(file_path, "w") as api_file:
    api_file.write(api_function)

  print(f"API function for {path} generated at {file_path}")

axios_catch_function = f"""
import {{ AxiosError }} from 'axios'
import {{ Notify }} from 'quasar'

export function throwError (error) {{
  if (error instanceof AxiosError) {{
    const message = error.response.data.message || `${{error.response.status}} - ${{error.response.statusText}}`
    Notify.create({{
      color: 'negative',
      position: 'top',
      message,
      icon: 'report_problem'
    }})
    console.error(message)
    console.trace()
  }}
}}
"""

axios_catch_path = os.path.join(output_folder, 'axios-catch.js')

with open(axios_catch_path, "w") as api_file:
  api_file.write(axios_catch_function)

print(f"axios error generated at {file_path}")