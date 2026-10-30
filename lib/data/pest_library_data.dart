
import '../models/pest_info.dart';

//

final List<PestInfo> pestLibraryData = [

  // ── PESTS ──────────────────────────────────────────────────────────────

  const PestInfo(
    id: 'rice_bug',
    name: 'Rice Bug',
    localName: 'Atangya',
    scientificName: 'Leptocorisa oratorius, L. acuta',
    type: PestType.pest,
    description:
        'Sinisipsip ng rice bug ang laman ng murang butil ng palay. '
        'Dahil dito, maaaring maging kulubot, walang laman, o may batik ang butil. '
        'Sa matinding pagdami, maaaring bumaba nang malaki ang ani.',
    cause:
        'Dumarami ito sa mga lugar na maraming damo, ligaw na damuhan, '
        'kakahuyan, o iba pang tirahan malapit sa palayan. '
        'Lumilipat ito sa palay kapag namumulaklak na, at mas dumarami kapag '
        'hindi sabay-sabay ang pagtatanim at mainit, maulap, o madalas umambon.',
    symptoms:
        'Maliit, kulubot, may batik, o walang laman ang mga butil. '
        'Maaaring makita ang payat na kayumanggi-berdeng insekto at '
        'mapula-kayumangging itlog sa gitnang ugat ng dahon.',
    prevention:
        'Tanggalin ang damo sa palayan at paligid nito. Magtanim nang sabay-sabay. '
        'Kung kaunti pa ang rice bug, hulihin gamit ang lambat tuwing umaga o hapon. '
        'Regular na suriin ang palayan bago mamulaklak hanggang sa pagbuo ng butil. '
        'Kung mahigit 10 rice bug sa 20 kumpol ng palay, kumonsulta muna sa '
        'agricultural technician bago gumamit ng pesticide.',

    images: [
      'assets/images/library/pest/ricebug.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'caseworm',
    name: 'Rice Caseworm',
    localName: 'Uod na may Kaha',
    scientificName: 'Nymphula depunctalis',
    type: PestType.pest,
    description:
        'Pinuputol ng uod ang dulo ng dahon at ginagawang kaha na '
        'lumulutang sa tubig. Kadalasan ay nakakabawi ang palay, ngunit '
        'maaari nitong maantala ang paghinog at pag-ani nang 7 hanggang 10 araw.',
    cause:
        'Mas karaniwan ito sa palayang laging may tubig, lalo na sa batang punla. '
        'Ang gamu-gamo ay aktibo sa gabi at naaakit sa ilaw.',
    symptoms:
        'May mga kahang dahon na lumulutang sa tubig. Tuwid ang putol ng dahon, '
        'parang ginupit, at may manipis na bahaging naiiwan na parang hagdan.',
    prevention:
        'Patuyuin ang palayan kung kinakailangan. Magtanim nang maaga at '
        'mas maluwag ang pagitan, mga 30 × 20 cm, at gumamit ng mas matandang punla. '
        'Protektahan ang gagamba, tutubi, ibon, at iba pang natural na kaaway. '
        'Iwasan ang paggamit ng pyrethroid kung hindi kailangan. '
        'Kumonsulta muna sa agricultural technician bago mag-spray.',

    images: [
      'assets/images/library/pest/rice_caseworm.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'stem_borer',
    name: 'Stem Borer',
    localName: 'Uod ng Tangkay (Stem Borer)',
    scientificName: 'Scirpophaga incertulas (yellow stem borer) and 5 other species',
    type: PestType.pest,
    description:
        'Bumubutas ang uod sa tangkay ng palay mula punla hanggang hustong gulang. '
        'Sa murang palay, nagdudulot ito ng tuyong gitnang suwi (deadheart). '
        'Sa namumulaklak o nagbubutil na palay, nagdudulot ito ng maputi at walang '
        'lamang uhay (whitehead). Kapag matindi, malaki ang maaaring mawala sa ani.',
    cause:
        'Mas dumadami kapag sobra ang nitrogen, huli ang pagtatanim, '
        'at may naiwang pinaggapasan na maaaring pamugaran ng uod at pupa.',
    symptoms:
        'Deadheart: tuyong gitnang suwi na madaling mabunot. '
        'Whitehead: maputi at walang lamang uhay. '
        'Maaari ring makita ang maliliit na butas at dumi ng uod sa loob ng tangkay.',
    prevention:
        'Gumamit ng barayting lumalaban. Magtanim sa tamang oras at sabay-sabay. '
        'Pagkatapos mag-ani, alisin ang pinaggapasan at tumubong palay; '
        'araruhin at bahain ang bukid kung angkop. Hatiin ang paglalagay ng nitrogen '
        'at iwasan ang sobrang abono. Huwag mag-spray nang walang malinaw na dahilan '
        'dahil maaari ring mapatay ang natural na kaaway ng peste. '
        'Kumonsulta muna sa agricultural technician bago mag-spray.',

    images: [
      'assets/images/library/pest/rice_borer.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'green_leafhopper',
    name: 'Green Leafhopper',
    localName: 'Berdeng Leafhopper',
    scientificName: 'Nephotettix virescens, N. malayanus',
    type: PestType.pest,
    description:
        'Sinisipsip ng berdeng leafhopper ang katas ng palay. '
        'Mas mahalaga itong bantayan dahil maaari nitong ikalat ang tungro '
        'at iba pang sakit na dulot ng virus.',
    cause:
        'Mas dumadami kapag hindi sabay-sabay ang pagtatanim at sobra ang nitrogen. '
        'Kapag kumain ito sa maysakit na palay, maaari nitong dalhin ang virus '
        'sa malulusog na halaman.',
    symptoms:
        'Maputlang berdeng insektong tumatalon o lumilipad sa palay. '
        'Maaaring maging bansot ang halaman, kaunti ang suwi, at manilaw o matuyo '
        'ang dahon, lalo na kapag may tungro.',
    prevention:
        'Gumamit ng barayting lumalaban sa tungro o leafhopper. '
        'Magtanim nang maaga at sabay-sabay, at iwasang magtanim sa panahong '
        'maraming leafhopper kung alam ang peak season sa lugar. '
        'Tanggalin ang damo at gumamit lamang ng kinakailangang nitrogen, '
        'gamit ang Leaf Color Chart kung available. Kung walang tungro sa lugar, '
        'iwasang mag-spray dahil kadalasan ay hindi ito epektibo. '
        'Kumonsulta muna sa agricultural technician bago mag-spray.',

    images: [
      'assets/images/library/pest/greenleafhopper.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'black_bug',
    name: 'Rice Black Bug',
    localName: 'Itim na Surot',
    scientificName: 'Scotinophara coarctata, S. lativentris, S. lurida',
    type: PestType.pest,
    description:
        'Sinisipsip ng itim na surot ang katas ng palay mula punla hanggang paghinog. '
        'Nagiging kayumanggi, bansot, at mahina ang palay. Kapag matindi, '
        'maaaring hindi makabuo ng butil ang halaman.',
    cause:
        'Mas karaniwan ito sa palayang siksik ang tanim, mahina ang daluyan ng tubig, '
        'o tuloy-tuloy ang pagtatanim. Maaari ring dumami kapag sobra ang nitrogen. '
        'Ang mga adult ay naaakit sa ilaw, lalo na malapit sa kabilugan ng buwan.',
    symptoms:
        'Mapula-kayumanggi o naninilaw na dahon, lantang suwi, at bansot na palay. '
        'Maaaring maliit, hindi lumabas, o walang lamang uhay. '
        'Sa deadheart na dulot ng black bug, hindi madaling mabunot ang apektadong suwi; '
        'naiiba ito sa stem borer na madaling mabunot.',
    prevention:
        'Gumamit ng barayting lumalaban at panatilihing malinis ang bukid. '
        'Magtanim ng barayting magkakalapit ang petsa ng pag-ani. '
        'Sa unang pagdami, maaaring taasan ang tubig sa loob ng 2 hanggang 3 araw '
        'at araruhin ang bukid pagkatapos mag-ani. '
        'Maaaring gumamit ng light trap bago at pagkatapos ng kabilugan ng buwan; '
        'ilagay ito sa ligtas na lugar, malayo sa tubig at kuryente. '
        'Protektahan ang natural na kaaway at kumonsulta bago mag-spray.',

    images: [
      'assets/images/library/pest/blackbug.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'planthopper',
    name: 'Planthopper (Brown and Whitebacked)',
    localName: 'Planthopper (BPH / WBPH)',
    scientificName: 'Nilaparvata lugens (BPH), Sogatella furcifera (WBPH)',
    type: PestType.pest,
    description:
        'Kapag marami ang planthopper, naninilaw hanggang kayumanggi at natutuyo '
        'ang palay (hopperburn), na maaaring makapatay ng halaman. '
        'Ang brown planthopper ay maaari ring magkalat ng Ragged Stunt at Grassy Stunt.',
    cause:
        'Mas dumadami sa palayang laging may tubig, mahalumigmig, malilim, '
        'siksik ang tanim, o sobra ang nitrogen. Lumalala kapag napapatay ng '
        'walang-kontrol na insecticide ang mga natural na kaaway nito.',
    symptoms:
        'May mga bahaging dilaw, kayumanggi, at tuyo (hopperburn). '
        'Maraming maliliit na insekto ang makikita malapit sa puno ng suwi. '
        'Maaari ring may malagkit na katas at itim na amag sa pinakailalim ng halaman.',
    prevention:
        'Gumamit ng barayting lumalaban at tanggalin ang damo. '
        'Regular na suriin ang punlaan at palayan. Protektahan ang gagamba at iba pang '
        'natural na kaaway. Iwasan ang walang-kontrol na insecticide. '
        'Kung kailangan ng pesticide, kumonsulta muna sa agricultural technician at '
        'sundin ang label ng produkto.',

    images: [
      'assets/images/library/pest/planthoppers.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  // ── DISEASES ───────────────────────────────────────────────────────────

  const PestInfo(
    id: 'tungro',
    name: 'Rice Tungro Disease',
    localName: 'Tungro',
    scientificName: 'Rice tungro virus complex (RTBV + RTSV)',
    type: PestType.disease,
    description:
        'Ang tungro ay sakit ng palay na dulot ng dalawang virus na naipapasa '
        'ng leafhopper, lalo na ng berdeng leafhopper. Nagdudulot ito ng '
        'paninilaw ng dahon, pagkabansot, kaunting suwi, at mga butil na walang '
        'laman o hindi kumpleto. Sa matinding kaso, maaaring umabot sa 100% ang pagkawala ng ani.',
    cause:
        'Naipapasa ang virus kapag kumakain ang leafhopper sa halamang may tungro '
        'at pagkatapos ay lumilipat sa malusog na palay. Maaaring manggaling ang virus '
        'sa dating pinaggapasan, tumubong palay, nahawang punla, o mga nahawang palay '
        'sa kalapit na bukid. Mas madalas makita ang tungro sa batang palay, lalo na sa pagsusuwi.',
    symptoms:
        'Nanilaw o naging dilaw-kahel ang dahon mula sa dulo pababa. '
        'Maaari ring magkaroon ng batik o guhit at mamula-kayumangging bahagi sa dahon. '
        'Ang halaman ay bansot, kaunti ang suwi, huli ang pamumulaklak, at maliit o '
        'hindi lubos na lumalabas ang uhay. Maraming uhay ang maaaring walang laman '
        'o bahagyang may butil lamang.',
    prevention:
        'Gumamit ng barayting lumalaban sa tungro o leafhopper. '
        'Magtanim nang sabay-sabay kasama ang mga kalapit na magsasaka at iwasang magtanim nang huli. '
        'Kung alam ang panahon na maraming green leafhopper, iwasang itapat dito ang pagtatanim. '
        'Pagkatapos anihin, araruhin agad ang pinaggapasan at alisin ang tumubong palay at damo. '
        'Hindi nagagamot ang halamang may tungro, kaya mas mahalaga ang pag-iwas kaysa paggamot. '
        'Kumonsulta muna sa agricultural technician bago gumamit ng pesticide.',

    images: [
      'assets/images/library/deseases/tungro.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'false_smut',
    name: 'False Smut',
    localName: 'False Smut',
    scientificName: 'Ustilaginoidea virens',
    type: PestType.disease,
    description:
        'Ang false smut ay sakit na dulot ng fungus na ginagawang bola ng spores '
        'ang ilang butil. Nagiging magaan at maputla ang butil at maaaring bumaba '
        'ang timbang at pagtubo ng binhi.',
    cause:
        'Kumakalat ang spores sa hangin at mas mabilis dumami kapag maulan, '
        'mataas ang halumigmig, mainit, at sobra ang nitrogen. Karaniwang nahahawa '
        'ang palay habang namumulaklak.',
    symptoms:
        'May malalambot na bolang parang amag sa ilang butil. Kahel muna ang mga ito '
        'at nagiging berde-itim habang tumatanda. Maaaring walang laman o maputla '
        'ang mga butil sa paligid.',
    prevention:
        'Gumamit ng sertipikadong binhi at barayting lumalaban. '
        'Salitan ang basa at tuyo (AWD) at iwasan ang sobrang nitrogen. '
        'Pagkatapos mag-ani, alisin ang nahawang uhay at kalat. '
        'Maaaring gamutin ang binhi sa 52 °C sa loob ng 10 minuto; mag-ingat upang hindi mapaso. '
        'Kung hahawak ng nahawang materyal o gagamit ng fungicide, magsuot ng angkop na proteksiyon.',

    images: [
      'assets/images/library/deseases/sheathrot.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'sheath_rot',
    name: 'Sheath Rot',
    localName: 'Sheath Rot',
    scientificName: 'Sarocladium oryzae',
    type: PestType.disease,
    description:
        'Ang sheath rot ay sakit na dulot ng fungus na nabubulok ang pinakataas '
        'na kaluban ng dahon. Nahihirapang lumabas ang uhay, kaya maaaring bumaba '
        'ang ani at maging walang laman o kupas ang mga butil.',
    cause:
        'Maaaring manggaling sa nahawang binhi at tirang halaman. '
        'Mas malala sa tag-ulan, siksik na tanim, mataas na halumigmig, at sobrang nitrogen. '
        'Ang sugat mula sa stem borer at ibang insekto ay maaaring pasukan ng fungus.',
    symptoms:
        'May pahaba o hindi regular na batik sa pinakataas na kaluban, '
        'mapula-kayumanggi ang gilid at abo o kulay-abo ang gitna. '
        'Maaaring may maputing amag. Ang uhay ay nananatili sa loob o bahagyang lumalabas '
        'at maaaring mabulok ang mga butil.',
    prevention:
        'Gumamit ng malusog na binhi at tamang pagitan ng tanim. '
        'Kontrolin ang stem borer at ibang insektong nagdudulot ng sugat. '
        'Alisin ang nahawang pinaggapasan pagkatapos anihin. '
        'Gumamit ng potash ayon sa rekomendasyon. Kung gagamit ng fungicide, '
        'sundin ang label at magsuot ng guwantes, maskara, at bota. '
        'Kumonsulta muna sa agricultural technician bago mag-spray.',

    images: [
      'assets/images/library/deseases/sheathrot.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'stem_rot',
    name: 'Stem Rot',
    localName: 'Stem Rot',
    scientificName: 'Sclerotium oryzae (Magnaporthe salvinii)',
    type: PestType.disease,
    description:
        'Ang stem rot ay sakit na dulot ng fungus na nabubulok ang tangkay malapit '
        'sa tubig. Maaaring humiga ang palay, mamatay ang ilang suwi, at magkaroon '
        'ng maraming butil na walang laman o maputla, kaya bumababa ang ani.',
    cause:
        'Nabubuhay ang fungus sa lupa at mga natirang dayami o pinaggapasan bilang maliliit '
        'na matitigas na butil. Maaari itong lumutang sa tubig-irigasyon at makahawa sa bagong tanim. '
        'Mas madaling mahawa ang palay na may sugat, napinsala ng insekto, o nahihiga.',
    symptoms:
        'May maliliit na itim na batik o sugat sa kaluban malapit sa tubig. '
        'Maaaring may puti o itim na maliliit na butil sa loob ng tangkay. '
        'Humihiga ang palay, namamatay ang mga suwi, at nagiging walang laman o maputla ang uhay.',
    prevention:
        'Gumamit ng barayting lumalaban. Pagkatapos mag-ani, alisin o hayaang mabulok nang maayos '
        'ang dayami at pinaggapasan at patuyuin ang bukid. Gumamit ng balanseng abono, '
        'lalo na potash, ayon sa rekomendasyon. Kung susunugin ang dayami, sundin ang lokal na patakaran '
        'at bantayan ang apoy. Kumonsulta muna sa agricultural technician bago mag-fungicide.',

    images: [
      'assets/images/library/deseases/steamrot.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

  const PestInfo(
    id: 'blb',
    name: 'Bacterial Leaf Blight',
    localName: 'Bacterial Leaf Blight (BLB) / Kresek',
    scientificName: 'Xanthomonas oryzae pv. oryzae',
    type: PestType.disease,
    description:
        'Ang bacterial leaf blight (BLB) ay sakit na dulot ng bacteria. '
        'Nagiging lanta ang punla at naninilaw at natutuyo ang dahon. '
        'Kapag maagang umatake, maaari itong magdulot ng malaking bawas sa ani.',
    cause:
        'Kumakalat ang bacteria sa mga patak na naililipat ng malakas na hangin at ulan, '
        'lalo na kapag may sugat ang dahon. Mas pabor dito ang mainit at mahalumigmig na panahon, '
        'sobra ang nitrogen, at may damo o pinaggapasan na may bacteria.',
    symptoms:
        'Sa batang palay (kresek), kumukulot ang dahon at nagiging abuhing berde, '
        'saka kulay-dayami bago malanta at mamatay. Sa matandang palay, may dilaw-kahel na '
        'guhit na alon-alon mula dulo ng dahon pababa. Maaari ring makita ang malagkit na '
        'puting gatas na patak sa bagong sugat, lalo na sa umaga.',
    prevention:
        'Gumamit ng barayting lumalaban dahil ito ang pinaka-maaasahan at matipid na paraan. '
        'Gumamit ng balanseng abono at iwasan ang sobrang nitrogen. Tiyaking maayos ang daluyan '
        'ng tubig. Tanggalin ang damo at araruhin ang pinaggapasan at tumubong punla. '
        'Patuyuin ang bukid kapag walang tanim. Maghugas ng kamay at kagamitan pagkatapos '
        'magtrabaho sa nahawang bukid.',

    images: [
      'assets/images/library/deseases/bacterialblight.png',
    ],

    imageCredit: 'Photos: IRRI',
  ),

];
