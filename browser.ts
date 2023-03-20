import {JupyterFrontEnd, JupyterFrontEndPlugin } from '@jupyterlab/application';
import { ICommandPalette } from '@jupyterlab/apputils';
import { IFileBrowserFactory} from '@jupyterlab/filebrowser';
import { extensionIcon } from '@jupyterlab/ui-components';
import { INotebookTracker, NotebookPanel } from '@jupyterlab/notebook';
import { PageConfig} from '@jupyterlab/coreutils';
import Dexie from 'dexie@*/dist/dexie';

const plugin = {
  id: 'dexie-browser:plugin',
  autoStart: true,
  requires: [ICommandPalette, IFileBrowserFactory, INotebookTracker],
  activate: async function (app, palette, factory, nbtracker) {
    let commandID = 'my:load-from-browser';
    const { defaultBrowser: browser } = factory;
    const autorunPath = PageConfig.getOption('autorun_notebook');

    const db = new Dexie('jupyter-offlinenotebook');
    db.version(1).stores({
        offlinenotebook: 'pk, repoid, name, type',
    });
    try {
      const contentsName = "browser.json";
      const keys = await db.offlinenotebook.orderBy('pk').primaryKeys();
      const file = new File([JSON.stringify(keys)], contentsName);
      browser.model.upload(file).then(model => {
        console.log("Table of contents uploaded: " + model.path);
      });
    } catch (error) {
      console.error(error);
    };

    app.serviceManager.ready.then(async () => {
      nbtracker.currentChanged.connect(async (_: INotebookTracker, nbPanel: NotebookPanel | null) => {
        if (nbPanel && autorunPath.endsWith(nbPanel.context.path)) {
          nbPanel.sessionContext.ready.then(() => {
            app.commands.execute('notebook:run-all-cells').then(() => {
              console.log("Autorun: " + nbPanel.context.path);
            });
          });
        };
      });
      await app.commands.execute('docmanager:open', {
        path: 'browser.ipynb'
      });
    });

    app.commands.addCommand(commandID, {
      label: 'Browser uploader (IndexedDB)',
      caption: 'Create notebook from browser',
      icon: extensionIcon,
      execute: async (args:any) => {
        const pk = args['pk'];
        console.log("Opening " + pk);

        db.offlinenotebook.get(pk).then(notebook => {
          const file = new File([JSON.stringify(notebook.content)], notebook.name);
          browser.model.upload(file).then(model => {
            app.commands.execute('docmanager:open', {
              path: model.path
            });
          });
        });
      };
    });
    palette.addItem({
      command: commandID,
      category: 'AAA' // Sort to the top
    });
  },
};
export default plugin;
