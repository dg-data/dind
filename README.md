### JupyterLab Binder content browser plugin

This plugin loads automatically on startup through [JupyterLab Plugin Playground](http://github.com/jupyterlab/jupyterlab-plugin-playground "JupyterLab Plugin Playground"). Then uses [ipylab ](http://github.com/jtpio/ipylab "ipylab ") to create a widget populating data fetched from the browser IndexedDB saved earlier by the [Jupyter Offline Notebook](http://github.com/manics/jupyter-offlinenotebook "Jupyter Offline Notebook") extension. The widget facilitates browsing and loading notebooks regardless of which github repo they were saved from.


------------

Basic steps:
- run this repo from [MyBinder](http://mybinder.org/v2/gh/dg-data/dind/main "MyBinder")
- Binder creates an image from [Dockerfile](http://github.com/dg-data/dind/blob/main/Dockerfile "Dockerfile") with all the neccessary packages installed
( ipylab, ipytree, jupyterlab-plugin-playground, jupyter-offlinenotebook )
- JupyterLab starts with the plugin specified in [plugin.jupyterlab-settings](http://github.com/dg-data/dind/blob/main/plugin.jupyterlab-settings "plugin.jupyterlab-settings"), which is [browser.ts](http://github.com/dg-data/dind/raw/main/browser.ts "browser.ts")
- the activated plugin reads database *jupyter-offlinenotebook* from your browser and saves its toc to *browser.json*
- it loads and runs the notebook configured in [jupyter_config.json](http://github.com/dg-data/dind/blob/main/jupyter_config.json "jupyter_config.json"), namely [browser.ipynb](http://github.com/dg-data/dind/blob/main/browser.ipynb "browser.ipynb")
- the notebook creates a new JupyterLab panel with an *ipytree* widget and some buttons
- on clicking the *Open* button it runs a command defined by the plugin which uploads the selected notebook from the previously saved ones to JupyterLab and opens it
