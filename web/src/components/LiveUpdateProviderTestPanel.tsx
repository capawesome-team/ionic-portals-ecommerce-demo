import React, { useState } from 'react';
import { IonButton, IonListHeader } from '@ionic/react';
import { registerPlugin } from '@capacitor/core';
import './LiveUpdateProviderTestPanel.scss';

interface IonicProviderTestPlugin {
  isProviderRegistered(): Promise<{ registered: boolean }>;
  getLatestAppDirectory(options: {
    liveUpdateTarget: 'help' | 'webapp' | 'featured';
  }): Promise<{ latestAppDirectory: string | null }>;
  syncManager(options: {
    liveUpdateTarget: 'help' | 'webapp' | 'featured';
  }): Promise<{ latestAppDirectory: string | null; metadata?: Record<string, unknown> }>;
}

const IonicProviderTest = registerPlugin<IonicProviderTestPlugin>('IonicProviderTest');

type LiveUpdateTarget = 'help' | 'webapp' | 'featured';

interface LiveUpdateProviderTestPanelProps {
  target?: LiveUpdateTarget;
}

const LiveUpdateProviderTestPanel: React.FC<LiveUpdateProviderTestPanelProps> = ({
  target = 'webapp',
}) => {
  const [providerTestOutput, setProviderTestOutput] = useState<string>('Not run yet.');
  const [providerTestRunning, setProviderTestRunning] = useState<boolean>(false);

  const runProviderTest = async (action: 'isProviderRegistered' | 'getLatestAppDirectory' | 'syncManager') => {
    setProviderTestRunning(true);
    try {
      let result: unknown;
      if (action === 'isProviderRegistered') {
        result = await IonicProviderTest.isProviderRegistered();
      } else if (action === 'getLatestAppDirectory') {
        result = await IonicProviderTest.getLatestAppDirectory({ liveUpdateTarget: target });
      } else {
        result = await IonicProviderTest.syncManager({ liveUpdateTarget: target });
      }
      setProviderTestOutput(JSON.stringify(result, null, 2));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      setProviderTestOutput(`Error: ${message}`);
    } finally {
      setProviderTestRunning(false);
    }
  };

  return (
    <div className="provider-test-panel">
      <IonListHeader>Live Update Provider Test</IonListHeader>
      <p className="provider-test-panel__help">
        Uses IonicProviderTest plugin with live update target <strong>{target}</strong>.
      </p>
      <div className="provider-test-panel__actions">
        <IonButton
          size="small"
          fill="outline"
          disabled={providerTestRunning}
          onClick={() => runProviderTest('isProviderRegistered')}
        >
          Is Provider Registered?
        </IonButton>
        <IonButton
          size="small"
          fill="outline"
          disabled={providerTestRunning}
          onClick={() => runProviderTest('getLatestAppDirectory')}
        >
          Get Latest App Directory
        </IonButton>
        <IonButton
          size="small"
          disabled={providerTestRunning}
          onClick={() => runProviderTest('syncManager')}
        >
          Sync Manager
        </IonButton>
      </div>
      <pre className="provider-test-panel__output">{providerTestOutput}</pre>
    </div>
  );
};

export default LiveUpdateProviderTestPanel;