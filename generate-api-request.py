import re
import os

input_file = "routes.js"
output_folder = "./api"

with open(input_file, "r") as file:
    content = file.read()

# Extract import statements using regex
imports = re.findall(r"import\s+{\s*([^}]+)\s*}\s+from\s+'([^']+)'", content)

# Create a dictionary to map function names to import paths
function_import_mapping = {func.strip(): path for func, path in imports}

# Extract endpoint information using regex
endpoints = re.findall(r"app\.(\w+)\(\s*'(\S+)',(?:\s*([^\s,]+)\s*,)?\s*(\w+)\)", content)

for method, path, middleware, controller in endpoints:
    function_name = f'{controller}'

    # Get the import path for the current function
    import_path = function_import_mapping.get(controller)

    if not import_path:
        print(f"Error: Import path not found for {controller}")
        continue

    # Construct the full path to the controller file
    controller_file = os.path.join(os.path.dirname(input_file), import_path)

    with open(controller_file, 'r') as file:
        controller_content = file.read()

    pattern = r'\b(\w+): z\.(\w+)\(\)'

    # Find all matches using re.findall
    matches = re.findall(pattern, controller_content)

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
 * @param {{{{body: Body, query: Query}}}} request{f'{new_line_space}* @param {{string}} token' if middleware else ''}
 * @returns
 */
export async function {function_name} (request{', token' if middleware else ''}) {{
  /** @type {{import('axios').AxiosRequestConfig}} */
  const axiosConfig = {{
    url: '{path}',
    method: '{method.upper()}',
    data: request?.body,
    params: request?.query{f''',
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
        os.makedirs(output_folder)

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

print(f"Axios error handling function generated at {axios_catch_path}")

