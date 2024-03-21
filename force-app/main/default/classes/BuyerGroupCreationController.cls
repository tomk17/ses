/**
* Controller for the Buyer Groups Creation
*
* @author		Benjamin Cligny - iCom Cloud
* Created Date	2023-01-18
* Used in
* Test class 
*
* Date       | Author							| Version | Changes
* ---------- | ------------------------------- |-------- | -----------------------------------------
* 2023-01-18 | Benjamin Cligny - iCom Cloud	|  1.0.0  | 
*/
public class BuyerGroupCreationController {
    Set<Id> children;
    List<BuyerAccount> buyerAccounts;
    List<SBQQ__ContractedPrice__c> cpsFromAccounts;
    
    Set<Id> parentAccountIds;
    List<BuyerGroupMember> bgmsFromParentAccounts;
    
    /*************************************************************/
    Set<Id> bgsIdsFromParentAccounts;
    
    List<BuyerGroupPricebook> bgpbsFromParentAccounts;
    List<CommerceEntitlementBuyerGroup> cebgsFromParentAccounts;
    
    Set<Id> pricebookIds;
    Set<Id> commerceEntitlementPolicyIds;
    List<PricebookEntry> pbesFromParentAccounts;
    List<CommerceEntitlementProduct> ceprodsFromParentAccounts;
    
    Map<String, List<PricebookEntry>> mapBuyerGroupNamePBEs;
    Map<String, List<CommerceEntitlementProduct>> mapBuyerGroupNameCEProds;
    /*************************************************************/
    
    List<Account> childAccounts;
    WebStore store;
    List<BuyerGroup> bgsToInsert;
    List<WebStoreBuyerGroup> sbgsToInsert;
    Map<String, Account> mapBGNameAccount;
    List<BuyerGroupMember> bgmsToInsert;
    Map<BuyerGroup, CommerceEntitlementPolicy> mapBuyerGroupCEP;
    List<CommerceEntitlementBuyerGroup> ebgsToInsert;
    Map<String, List<SBQQ__ContractedPrice__c>> mapBuyerGroupNameCPs;
    List<CommerceEntitlementProduct> ceprodsToInsert;
    Map<BuyerGroup, Pricebook2> mapBuyerGroupPB;
    List<BuyerGroupPricebook> bgpbsToInsert;
    List<PricebookEntry> pbesToInsert;
    List<Account> listAccounts;
    
    Map<String, String> mapBgNameCurrency;
        
    public BuyerGroupCreationController(List<Account> listAccounts){
        this.listAccounts = listAccounts;
        this.buyerAccounts = [SELECT Id, BuyerId, isActive FROM BuyerAccount WHERE BuyerId IN :listAccounts];
        this.cpsFromAccounts = [SELECT Id, SBQQ__Account__c, CurrencyIsoCode, SBQQ__Product__c, SBQQ__Product__r.MaterialStatus__c, SBQQ__Price__c, SwapPrice__c, Restock_MROPrice__c, NewInstallPrice__c FROM SBQQ__ContractedPrice__c WHERE SBQQ__Account__c IN :listAccounts];
        
        this.parentAccountIds = new Set<Id>();
        for(Account acc : listAccounts){
            parentAccountIds.add(acc.ParentId);
        }
        this.bgmsFromParentAccounts =  [SELECT BuyerGroupId, BuyerId FROM BuyerGroupMember WHERE BuyerId IN :parentAccountIds];

        /*************************************************************/
        this.bgsIdsFromParentAccounts = new Set<Id>();
        for(BuyerGroupMember bgm : bgmsFromParentAccounts){
            bgsIdsFromParentAccounts.add(bgm.BuyerGroupId);
        }
        
        this.bgpbsFromParentAccounts = [SELECT Id, Pricebook2Id, BuyerGroupId FROM BuyerGroupPricebook WHERE BuyerGroupId IN :bgsIdsFromParentAccounts];
        this.cebgsFromParentAccounts = [SELECT Id, PolicyId, BuyerGroupId FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId IN :bgsIdsFromParentAccounts];
        
        this.pricebookIds = new Set<Id>();
        for(BuyerGroupPricebook bgpb : bgpbsFromParentAccounts){
            pricebookIds.add(bgpb.Pricebook2Id);
        }
        this.pbesFromParentAccounts  = [SELECT Id, isActive, UnitPrice, Product2Id, Pricebook2Id FROM PricebookEntry WHERE Pricebook2Id IN: pricebookIds];
        
        this.commerceEntitlementPolicyIds = new Set<Id>();
        for(CommerceEntitlementBuyerGroup cebg : cebgsFromParentAccounts){
            commerceEntitlementPolicyIds.add(cebg.PolicyId);
        }
        this.ceprodsFromParentAccounts  = [SELECT Id, PolicyId, ProductId FROM CommerceEntitlementProduct WHERE PolicyId IN: commerceEntitlementPolicyIds];
        
        this.mapBuyerGroupNamePBEs = new Map<String, List<PricebookEntry>>();
        this.mapBuyerGroupNameCEProds = new Map<String, List<CommerceEntitlementProduct>>();
        /*************************************************************/    
        
        this.childAccounts = [SELECT Id, ParentId, Name, CurrencyIsoCode FROM Account WHERE ParentId IN :listAccounts];
        this.store = [SELECT Id From WebStore WHERE Name = 'SES B2B Commerce'];
        this.bgsToInsert = new List<BuyerGroup>();
        this.sbgsToInsert = new List<WebStoreBuyerGroup>();
        this.mapBGNameAccount = new Map<String, Account>();
        this.bgmsToInsert = new List<BuyerGroupMember>();
        this.mapBuyerGroupCEP = new Map<BuyerGroup, CommerceEntitlementPolicy>();
        this.ebgsToInsert = new List<CommerceEntitlementBuyerGroup>();
        this.mapBuyerGroupNameCPs = new Map<String, List<SBQQ__ContractedPrice__c>>();
        this.ceprodsToInsert = new List<CommerceEntitlementProduct>();
        this.mapBuyerGroupPB = new Map<BuyerGroup, Pricebook2>();
        this.bgpbsToInsert = new List<BuyerGroupPricebook>();
        this.pbesToInsert = new List<PricebookEntry>();
        this.children = new Set<Id>();
        
        this.mapBgNameCurrency = new Map<String, String>();
    }
    
    public void clearAllExistingObjects(){
        List<BuyerGroupMember> existingBGMs = [SELECT BuyerId, BuyerGroupId FROM BuyerGroupMember WHERE BuyerId IN :listAccounts];
        Set<Id> buyerGroupIds = new Set<Id>();
        for(BuyerGroupMember bgm : existingBGMs){
            buyerGroupIds.add(bgm.BuyerGroupId);
        }
        List<BuyerGroup> existingBGs = [SELECT Id FROM BuyerGroup WHERE Id IN :buyerGroupIds];
        List<WebStoreBuyerGroup> existingWBGs = [SELECT Id FROM WebStoreBuyerGroup WHERE BuyerGroupId IN :existingBGs];
        List<CommerceEntitlementBuyerGroup> existingsCEBGs = [SELECT Id, PolicyId FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId IN :existingBGs];
        Set<Id> entitlementPolicyIds = new Set<Id>();
        for(CommerceEntitlementBuyerGroup cebg : existingsCEBGs){
            entitlementPolicyIds.add(cebg.PolicyId);
        }
        List<CommerceEntitlementPolicy> existingCEPs = [SELECT Id FROM CommerceEntitlementPolicy WHERE Id IN :entitlementPolicyIds];
        List<CommerceEntitlementProduct> existingCEProds = [SELECT Id FROM CommerceEntitlementProduct WHERE PolicyId IN :existingCEPs];
        List<BuyerGroupPricebook> existingsBGPBs = [SELECT Id, Pricebook2Id FROM BuyerGroupPricebook WHERE BuyerGroupId IN :existingBGs];
        Set<Id> pricebookIds = new Set<Id>();
        for(BuyerGroupPricebook bgp : existingsBGPBs){
            pricebookIds.add(bgp.Pricebook2Id);
        }
        List<Pricebook2> existingPBs = [SELECT Id FROM Pricebook2 WHERE Id IN :pricebookIds AND Name LIKE '%- Buyer Group - Price Book%'];
        List<PricebookEntry> existingPBEs = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id IN :existingPBs];
        delete existingPBEs; //Pricebook entries
        delete existingCEProds; //Commerce Entitlement Products
        delete existingsCEBGs; //Commerce Entitlement Buyer Groups   
        delete existingsBGPBs; //Buyer Group Price Books
        delete existingPBs; //Pricebooks
        delete existingCEPs; //Commerce Entitlement policies
        delete existingWBGs; //WebStore Buyer Groups
        delete existingBGMs; //Buyer Group Members
        delete existingBGs; //Buyer Groups
    }
    
     //ici on prépare les enfants de cet account pour le prochain traitement
    public void setChildren(){
        for(Account acc : listAccounts){
            for(Account accChild : childAccounts){
                if(accChild.parentId == acc.Id && !children.contains(accChild.Id)){
                    System.debug('ajout de ' + accChild.Name + ' pour ' + acc.Name);
                    children.add(accChild.Id);
                }
            }
        }
    }
    
    public Set<Id> getChildren(){
        return this.children;
    }
    
    public void buyerAccountsCreation(){
        Set<Id> accountIdsWithBA = new Set<Id>();
        List<BuyerAccount> basToInsert = new List<BuyerAccount>();
                
        for(BuyerAccount BA : buyerAccounts){
            BA.IsActive = true;
            accountIdsWithBA.add(BA.BuyerId);
        }
        
        List<Account> listTest = [SELECT id, name FROM Account WHERE id in:accountIdsWithBA];
        
        for(Account acc : listTest){
            System.debug('BEN DEBUG ACCOUNT WITH BA  : ' + acc.name);
        }
        
        for(Account acc : listAccounts){
            if(!accountIdsWithBA.contains(acc.Id)){
                BuyerAccount baToInsert = new BuyerAccount(BuyerId = acc.Id, BuyerStatus = 'Active', CommerceType = 'Acheteur', IsActive = true, Name = 'Buyer Account Of ' + acc.Name);
                basToInsert.add(baToInsert);
            }
        }
        System.debug('BEN DEBUG BAS : ' + basToInsert);
        insert basToInsert;
    }
    
    public List<BuyerGroupMember> getBGMsFromPAOfThisAccount(Account acc){
        List<BuyerGroupMember> bgmsFromPAOfThisAccount= new List<BuyerGroupMember>();
        for(BuyerGroupMember BGM : this.bgmsFromParentAccounts){
            if(BGM.BuyerId == acc.ParentId){
                bgmsFromPAOfThisAccount.add(BGM);
            }
        }
        
        return bgmsFromPAOfThisAccount;
    }
    
    public List<SBQQ__ContractedPrice__c> getCPsFromThisAccount(Account acc){
        List<SBQQ__ContractedPrice__c> cpsFromThisAccount = new List<SBQQ__ContractedPrice__c>();
        for(SBQQ__ContractedPrice__c CP : cpsFromAccounts){
            if(CP.SBQQ__Account__c == acc.Id){
                cpsFromThisAccount.add(CP);
            }
        }
        return cpsFromThisAccount;
    }
    
    public String addToBGsToInsert(Account acc){
        String bgName = acc.Name + ' - ' + acc.AccountNumber + ' - Buyer Group';
        BuyerGroup BGToInsert = new BuyerGroup(Name = bgName);
        bgsToInsert.add(BGToInsert);
        return bgName;
    }
    
    public void addToBGMSToInsert(Account acc, List<BuyerGroupMember> bgmsFromPAOfThisAccount){
        if(acc.ParentId != null){
            String parentAcountId = acc.ParentId;
            Account parentAccount = [SELECT Id, CurrencyIsoCode FROM Account WHERE Id =:parentAcountId];
            if(bgmsFromPAOfThisAccount.size() > 0 && acc.CurrencyIsoCode == parentAccount.CurrencyIsoCode){
                //Tous les buyerGroups où le parentAccount est présent
                for(BuyerGroupMember BGM : bgmsFromPAOfThisAccount){
                    BuyerGroupMember BGMToInsert = new BuyerGroupMember(BuyerId = acc.Id, BuyerGroupId = BGM.BuyerGroupId);
                    bgmsToInsert.add(BGMToInsert);
                }
            }
        }
    }
    
    public void createClonesAndPopulateMaps(Account acc, String bgName, List<SBQQ__ContractedPrice__c> cpsFromThisAccount, List<BuyerGroupMember> bgmsFromPAOfThisAccount){
        
        mapBGNameAccount.put(bgName, acc);
        
        /*****************************************************************/
        
        //je veux tous les ids des buyer group du parent account
        Set<Id> idsBGsFromPAOfThisAccount = new Set<Id>();
        for(BuyerGroupMember bgm : bgmsFromPAOfThisAccount){
            idsBGsFromPAOfThisAccount.add(bgm.BuyerGroupId);
        }
        
        //je recupère tous les Pricebook lié à mon parentAccount grace à ma liste d'ids bg set au dessus + ma liste de bgpbs globale set dans le constructeur
        Set<Id> idsPBsFromPAOfThisAccount = new Set<Id>();
        System.debug('Pour acc name : ' + acc.Name + ' bgpbsFromParentAccounts : ' + bgpbsFromParentAccounts);
        for(BuyerGroupPricebook bgpb : bgpbsFromParentAccounts){
            if(idsBGsFromPAOfThisAccount.contains(bgpb.BuyerGroupId)){
                System.debug('COUCOU PB');
                idsPBsFromPAOfThisAccount.add(bgpb.Pricebook2Id);
            }
        }
        
        //je recupère tous les Entitlement policy lié à mon parentAccount grace à ma liste d'ids bg set au dessus + ma liste de cebg globale set dans le constructeur
        Set<Id> idsCEPsFromPAOfThisAccount = new Set<Id>();
        System.debug('Pour acc name : ' + acc.Name + ' cebgsFromParentAccounts : ' + cebgsFromParentAccounts);
        for(CommerceEntitlementBuyerGroup cebg : cebgsFromParentAccounts){
            if(idsBGsFromPAOfThisAccount.contains(cebg.BuyerGroupId)){
                System.debug('COUCOU CEP');
                idsCEPsFromPAOfThisAccount.add(cebg.PolicyId);
            }
        }
        
        System.debug('Pour acc name : ' + acc.Name + ' idsPBsFromPAOfThisAccount : ' + idsPBsFromPAOfThisAccount);
        System.debug('Pour acc name : ' + acc.Name + ' idsCEPsFromPAOfThisAccount : ' + idsCEPsFromPAOfThisAccount);
        
        //Je clone les pricebookentry du parentAccount grace à ma liste d'ids pb set au dessus + ma liste pbes globale set dans le constructeur
        List<PricebookEntry> pbesCloned = new List<PricebookEntry>();
        for(PricebookEntry pbe : pbesFromParentAccounts){
            if(idsPBsFromPAOfThisAccount.contains(pbe.Pricebook2Id)){
                //mapBuyerGroupNamePBEs.get(bgName).add(pbe.clone(false, false, false, false));
                pbesCloned.add(pbe.clone(false, false, false, false));
            }
        }
        
        //Je clone les CommerceEntitlementProduct du parentAccount grace à ma liste d'ids cep set au dessus + ma liste ceprods globale set dans le constructeur
        List<CommerceEntitlementProduct> ceprodsCloned = new List<CommerceEntitlementProduct>();
        for(CommerceEntitlementProduct ceprods : ceprodsFromParentAccounts){
            if(idsCEPsFromPAOfThisAccount.contains(ceprods.PolicyId)){
                //mapBuyerGroupNamePBEs.get(bgName).add(pbe.clone(false, false, false, false));
                ceprodsCloned.add(ceprods.clone(false, false, false, false));
            }
        }
        
        System.debug('Pour acc name : ' + acc.Name + ' pbesCloned : ' + pbesCloned);
        System.debug('Pour acc name : ' + acc.Name + ' ceprodsCloned : ' + ceprodsCloned);

        
        //Je recupère un set d'id prod depuis les contracted price de mon account
        Set<Id> productIdsFromCps = new Set<Id>();
        for(SBQQ__ContractedPrice__c cp : cpsFromThisAccount){
            productIdsFromCps.add(cp.SBQQ__Product__c);
        }
        
        //Je peuple la map qui contient les pbe du parent que je vais devoir insérer sur le compte enfant, j'ajoute pas si l'enfant a deja un contracted price sur un des produits des pbe
        mapBuyerGroupNamePBEs.put(bgName, new List<PricebookEntry>());
        for(PricebookEntry pbe : pbesCloned){
            if(!productIdsFromCps.contains(pbe.Product2Id)){
                mapBuyerGroupNamePBEs.get(bgName).add(pbe);
            }
        }
        
        //Je peuple la map qui contient les ceprods du parent que je vais devoir insérer sur le compte enfant, j'ajoute pas si l'enfant a deja un contracted price sur un des produits des ceprods
        mapBuyerGroupNameCEProds.put(bgName, new List<CommerceEntitlementProduct>());
        for(CommerceEntitlementProduct ceprods : ceprodsCloned){
            System.debug('Pour acc name : ' + acc.Name + ' Pour ceprods : ' + ceprods);
            if(!productIdsFromCps.contains(ceprods.ProductId)){
                System.debug('Je suis rentré pour ceprods : ' + ceprods);
                mapBuyerGroupNameCEProds.get(bgName).add(ceprods);
            }
        }
        /*****************************************************************/
        
        //Création d'une entrée dans la map qui lie le buyer group aux produits des contracted prices
        mapBuyerGroupNameCPs.put(bgName, new List<SBQQ__ContractedPrice__c>());
        //Parcours sur seulement les CPs de ce compte
        for(SBQQ__ContractedPrice__c CP : cpsFromThisAccount){
            //Peuplement de la map qui lie le buyer group aux produits des contracted prices
            if(CP.Restock_MROPrice__c != null){
                mapBuyerGroupNameCPs.get(bgName).add(CP);
            }
        }
    }
    
    public void createBuyerGroups(){
        for(Account acc : listAccounts){
            List<BuyerGroupMember> bgmsFromPAOfThisAccount =  getBGMsFromPAOfThisAccount(acc);
            List<SBQQ__ContractedPrice__c> cpsFromThisAccount = getCPsFromThisAccount(acc);
            //Parcours sur tout les CPs lié à la liste de compte en entrée
            //Si il y a effectivement des CPs
            if(cpsFromThisAccount.size()>0){
                String bgName = addToBGsToInsert(acc);
                mapBgNameCurrency.put(bgName, acc.CurrencyIsoCode);
                createClonesAndPopulateMaps(acc, bgName, cpsFromThisAccount, bgmsFromPAOfThisAccount);
            }else{
                addToBGMSToInsert(acc, bgmsFromPAOfThisAccount);
            }
        }
        //Insertion des BuyerGroup
        insert bgsToInsert;
    }
    
    public String getCurrencyFromAccount(BuyerGroup BG){
        String currencyFromAccount = '';
        for(String bgName : mapBgNameCurrency.keySet()){
            if(BG.Name == bgName){
                currencyFromAccount = mapBgNameCurrency.get(bgName);
            }
        }
        return currencyFromAccount;
    }
    
    public void createObjectsAndPopulateMaps(BuyerGroup BG){
        WebStoreBuyerGroup SBGToInsert = new WebStoreBuyerGroup(BuyerGroupId = BG.Id, WebStoreId = store.Id);
        sbgsToInsert.add(SBGToInsert);
        //Création d'un entitlement policy / BG
        CommerceEntitlementPolicy CEPToInsert = new CommerceEntitlementPolicy(Name = BG.Name + ' - Entitlement Policy', IsActive = true, CanViewPrice = true, CanViewProduct = true);
        mapBuyerGroupCEP.put(BG, CEPToInsert);
        //Création d'un pricebook / BG
        String currencyFromAccount = getCurrencyFromAccount(BG);
        System.debug('currencyFromAccount : ' + currencyFromAccount);
        Pricebook2 PBToInsert = new Pricebook2(Name = BG.Name + ' - Price Book', CurrencyIsoCode = currencyFromAccount, IsActive = true, TECH_isB2B__c = true);
        mapBuyerGroupPB.put(BG, PBToInsert);
        for(String bgName : mapBGNameAccount.keySet()){
            if(bgName == BG.Name){
                BuyerGroupMember BGMToInsert = new BuyerGroupMember(BuyerId = mapBGNameAccount.get(bgName).Id, BuyerGroupId = BG.Id);
                bgmsToInsert.add(BGMToInsert);
            }
        }
    }
    
    public void createLinksForPricebooksAndEntitlements(BuyerGroup BG){
        CommerceEntitlementBuyerGroup EBGToInsert = new CommerceEntitlementBuyerGroup(BuyerGroupId = BG.Id, PolicyId = mapBuyerGroupCEP.get(BG).Id);
        ebgsToInsert.add(EBGToInsert);
        BuyerGroupPricebook BGPBToInsert = new BuyerGroupPricebook(BuyerGroupId = BG.Id, Pricebook2Id = mapBuyerGroupPB.get(BG).Id, IsActive = true);
        bgpbsToInsert.add(BGPBToInsert);
    }
    
    public void createEntriesFromContractedPrices(){
        //FROM CPS
        for(String BGName : mapBuyerGroupNameCPs.keyset()){
            Set<Id> idProducts = new Set<Id>();
            for(SBQQ__ContractedPrice__c CP : mapBuyerGroupNameCPs.get(BGName)){
                for(BuyerGroup BG : bgsToInsert){
                    if(BG.Name == BGName && (CP.SBQQ__Product__r.MaterialStatus__c != 'Blocked for Procurement (05)' && CP.SBQQ__Product__r.MaterialStatus__c != 'Blocked for Sales (Z6)' && CP.SBQQ__Product__r.MaterialStatus__c != 'Inactive (Z7)')){
                        if(!idProducts.contains(CP.SBQQ__Product__c)){
                            CommerceEntitlementProduct CEProdToInsert = new CommerceEntitlementProduct(PolicyId = mapBuyerGroupCEP.get(BG).Id, ProductId = CP.SBQQ__Product__c);
                            ceprodsToInsert.add(CEProdToInsert);
                        }
                        idProducts.add(CP.SBQQ__Product__c);
                        System.debug('CP.CurrencyIsoCode : ' + CP.CurrencyIsoCode);
                        PricebookEntry PBEToInsert = new PricebookEntry(Pricebook2Id = mapBuyerGroupPB.get(BG).Id, Product2Id = CP.SBQQ__Product__c, UnitPrice = CP.Restock_MROPrice__c.setScale(2, RoundingMode.HALF_UP), CurrencyIsoCode = CP.CurrencyIsoCode, IsActive = true);
                        pbesToInsert.add(PBEToInsert);
                    }
                }
            }
        }
        //FROM CLONED FOR PBE
        for(String BGName : mapBuyerGroupNamePBEs.keyset()){
            for(PricebookEntry pbe : mapBuyerGroupNamePBEs.get(BGName)){
                for(BuyerGroup BG : bgsToInsert){
                    if(BG.Name == BGName){
                        pbe.Pricebook2Id = mapBuyerGroupPB.get(BG).Id;
                        pbe.CurrencyIsoCode = mapBgNameCurrency.get(BGName);
                        pbesToInsert.add(pbe);
                    }
                }
            }
        }
        //FROM CLONED FOR CEPRODS
        for(String BGName : mapBuyerGroupNameCEProds.keyset()){
            for(CommerceEntitlementProduct ceprods : mapBuyerGroupNameCEProds.get(BGName)){
                for(BuyerGroup BG : bgsToInsert){
                    if(BG.Name == BGName){
                        ceprods.PolicyId = mapBuyerGroupCEP.get(BG).Id;
                        ceprodsToInsert.add(ceprods);
                    }
                }
            }
        }
    }
    
    public void buyerGroupCreation(){
		createBuyerGroups();	
        //Boucle sur les BuyerGroup maintenant créés
        for(BuyerGroup BG : bgsToInsert){
            //Ici on créé l'objet qui fait le lien pour chaque Buyer Group avec le store
            //On créé un Entitlement Policy par Buyer Group qu'on lie avec une map (on créera l'objet qui fait le lien une fois les Entitlement Policy insérés)
            //On créé un Price book par BuyerGroup qu'on lie avec une map (on créera l'objet qui fait le lien une fois les Price book insérés)
            //On créé le BuyerGroupMember qui lie le BuyerGroup à son Account
            createObjectsAndPopulateMaps(BG);
        }
        //insertion des WebStoreBuyerGroup créés au dessus
        insert sbgsToInsert;
        //insertion des BuyerGroupMember créés au dessus
        set<Id> idsaccs = new Set<Id>();
        for(BuyerGroupMember bgm : bgmsToInsert){
            idsaccs.add(bgm.BuyerId);
        }
        for(Account acc : [SELECT Id, Name FROM Account where id in :idsaccs]){
            System.debug('BEN DEBUG ' + acc.Name + '     ' + acc.Id);
        }
        
        insert bgmsToInsert;
        //insertion des Commerce Entitlement Policy créés au dessus
        insert mapBuyerGroupCEP.values();
        //insertion des Price books créés au dessus
        insert mapBuyerGroupPB.values();
        //Une fois les Commerce Entitlement Policy et les Price books créés, création des lien entre les Entitlement policy et les Price books avec les buyer groups
        for(BuyerGroup BG : mapBuyerGroupCEP.keySet()){
            createLinksForPricebooksAndEntitlements(BG);
        }
        //insertion des CommerceEntitlementBuyerGroup maintenant créées qui servent à faire le lien entre les Buyer Group et les Entitlement Policy
        insert ebgsToInsert;
        System.debug('ebgsToInsert : ' + ebgsToInsert);
        //insertion des BuyerGroupPricebook maintenant créées qui servent à faire le lien entre les Buyer Group et les Price Book
        insert bgpbsToInsert;
        System.debug('bgpbsToInsert : ' + bgpbsToInsert);
        //Une fois le lien établie entre un entitlement policy et un pricebook avec son buyer group, il faut parcourir les contracted prices pour créer les entrées (pricebook entry / CommerceEntitlementProduct)
        createEntriesFromContractedPrices();
        //Insertion des entries maintenant créées
        System.debug('ceprodsToInsert : ' + ceprodsToInsert);
        Database.insert(ceprodsToInsert, false);
        System.debug('pbesToInsert : ' + pbesToInsert);
        Database.insert(pbesToInsert, false);
        //Enfin, on applique le même processus aux comptes situés un niveau en dessous dans la hiéarchie
        //return children;
    }
}