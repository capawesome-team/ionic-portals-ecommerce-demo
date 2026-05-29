import React from 'react';
import { IonButton, IonContent, IonPage } from '@ionic/react';
import LiveUpdateProviderTestPanel from '../../components/LiveUpdateProviderTestPanel';

const DevPage: React.FC = () => (
  <IonPage>
    <IonContent>
      <IonButton expand="block" href="/help">
        Help Portal
      </IonButton>
      <IonButton expand="block" href="/user">
        Profile Portal
      </IonButton>
      <IonButton expand="block" href="/cart-total">
        Cart Portal
      </IonButton>
      <IonButton expand="block" href="/checkout">
        Checkout Modal Portal
      </IonButton>
      <IonButton expand="block" href="/new-featured">
        New Featured Component
      </IonButton>
      <LiveUpdateProviderTestPanel target="webapp" />
    </IonContent>
  </IonPage>
);

export default DevPage;
