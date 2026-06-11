import { Stylist, Salon, Booking, ChatMessage } from './types';

export const salonsData: Salon[] = [
  {
    id: 's1',
    name: 'Maison de Beauté',
    location: '尖沙咀海港城',
    distance: 0.5,
    rating: 4.9,
    tags: ['歐美染髮', '手刷染'],
    openHours: '10:00 - 20:00',
    phone: '+852 2345 6789',
    startPrice: 1200,
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD4A1j97kK_sgIZMYsicaVQnPcW_7T0XehJjQcqcVk68cUcGz1lGHSRUFn0xNQHYGMs5ApDnSwecdHwsnTqYMLHdxWjQ8c10OHqMQje4OI_sk9HMUGUr3XB99uM54np-H4a-vxs-qO2K4iAbEFT_hKMURbLnCZpZ8_8UUY5RXQWGe_eqLUZZUlBH5eR-EgqWFFlBlhwcEVhGK_gzSMUDx7b6xvIcFSo8UyeM-qeIxy_DuIxboSeNTOxoLQBiXpsm7oezF1mY3qDrpQ'
  },
  {
    id: 's2',
    name: 'Noir Studio',
    location: '中環國際金融中心',
    distance: 1.2,
    rating: 4.8,
    tags: ['男士理髮', '英式油頭', '漸層推剪'],
    openHours: '11:00 - 21:00',
    phone: '+852 9876 5432',
    startPrice: 800,
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDjxPbEIx45OCMBgJZtxL55Y95TPAK7olPj67xmiv8Phfba4imdTcf8Gbqzcf1XPizbcFKmyN7i1jBVkWRib7fSijLwTUc3qCAld5n3GIKBBEA2J83hrNhC5wUesiOP_Au3KwIJWrhoZMHqoPaxxlHgelv1Bdr-G4OAzTs0lFGdnw6hzBNqa9bHP2kvqo6y8CRdBmUk_BWs0Z5gHLjJbTbLpxXS9WywwJyoGQAaJmupok2zAezEwWk5P1fiVRmbRBpCQUcARfx2Z6Q'
  },
  {
    id: 's3',
    name: 'Zenith Premium Salon',
    location: '銅鑼灣時代廣場',
    distance: 1.8,
    rating: 4.9,
    tags: ['韓式燙髮', '縮毛矯正', '女神大波浪'],
    openHours: '10:00 - 21:00',
    phone: '+852 2882 1122',
    startPrice: 1500,
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDbQDYeFA5hdalzVV3rmfdIXTJaDaqTrP_pqDLAXyr9s2MLHPYRR9p-SJwq_z5z6KE_COPnoEXdVXVuKs3_lyPHQPLU0eAfRn6W21CSn4rviNSVy9JYb8Tn3ggMHZJPyYi3XGEDqH1mCcJxpNU__46yE-9CONd9MpN1kZuSQ1MkfKXCh7uFTWOWIPmz-zXnJliZVqoGxSnPTK85d0cU_63-mdy6sdfHJERQh_FguqeXiyrffxSM4g-bRnjMYnX4BNjBK7o5oZuWME0'
  },
  {
    id: 's4',
    name: 'Elysian Hair Art',
    location: '旺角朗豪坊',
    distance: 2.3,
    rating: 4.7,
    tags: ['裙擺染', '縮毛矯正', '線條感挑染'],
    openHours: '11:00 - 22:00',
    phone: '+852 2772 3344',
    startPrice: 500,
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD5Mjpv2OLnoQKABkYYklMNwC0Nuqry8RC52CMwQRI5-OQ5Oe7ZDPkqIObquL5mk9JL9UvTTsFPLJRF54r7LU8mIsvDstSjbkLkQFEC5I_Tt2firXsLwkLJbgTMzmbojD2iKKxhwTnHpj1Cv-nS_i9SlZmxuhn3CFC9Dis9Y5XOpl9l7mZLilVVwrIlmQcqEcBydLpDilsZdOmbam7hgBjtofsdeDvhJAZh7TNBiGxyNn7k730z_ULt_iCFQLrhDquSu4st7RFAadg'
  }
];

export const stylistsData: Stylist[] = [
  {
    id: 'master-leo',
    name: 'Master Leo',
    title: '首席設計師',
    rating: 4.9,
    reviewsCount: 124,
    languages: '中 / 英',
    experience: '10年以上',
    specialties: ['挑染專家', '經典剪髮'],
    avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD3FbJKj8QqvwIhm0BrWvW9dPnOy_Nf_3zuQv_AQ4D34uLm2YaK6ggyr2ZRk0-GMQyLM84ayUQxV07PUuAthEZD593Ld8oVujNA_DeXlL82jMZjSDY9R10UXgz4n8sxAKWOjST25SRW0rhwY9thezHurEdis9pNBHp5xeTjVJhyfLaeQs2mMSKktd5k_TJWoi98wtcowC71pNt2_ZH5-nrkfGTAesDSNgyp5zt_roBkAu9mR32Te_TbijU71PuvzMAJ3mLytVeDdeM',
    works: [
      {
        id: 'w1',
        title: '金色巴黎畫染',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDbQDYeFA5hdalzVV3rmfdIXTJaDaqTrP_pqDLAXyr9s2MLHPYRR9p-SJwq_z5z6KE_COPnoEXdVXVuKs3_lyPHQPLU0eAfRn6W21CSn4rviNSVy9JYb8Tn3ggMHZJPyYi3XGEDqH1mCcJxpNU__46yE-9CONd9MpN1kZuSQ1MkfKXCh7uFTWOWIPmz-zXnJliZVqoGxSnPTK85d0cU_63-mdy6sdfHJERQh_FguqeXiyrffxSM4g-bRnjMYnX4BNjBK7o5oZuWME0'
      },
      {
        id: 'w2',
        title: '精準漸層剪裁',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD5Mjpv2OLnoQKABkYYklMNwC0Nuqry8RC52CMwQRI5-OQ5Oe7ZDPkqIObquL5mk9JL9UvTTsFPLJRF54r7LU8mIsvDstSjbkLkQFEC5I_Tt2firXsLwkLJbgTMzmbojD2iKKxhwTnHpj1Cv-nS_i9SlZmxuhn3CFC9Dis9Y5XOpl9l7mZLilVVwrIlmQcqEcBydLpDilsZdOmbam7hgBjtofsdeDvhJAZh7TNBiGxyNn7k730z_ULt_iCFQLrhDquSu4st7RFAadg'
      }
    ],
    services: [
      {
        id: 's_cut',
        name: '招牌剪髮',
        category: '剪髮',
        duration: 60,
        description: '含洗髮與造型 • 60 分鐘',
        price: 80
      },
      {
        id: 's_color',
        name: '全頭染髮與光澤護理',
        category: '染髮',
        duration: 120,
        description: '頂級有機染劑 • 120 分鐘',
        price: 150
      },
      {
        id: 's_spa',
        name: '巴西生命果護髮',
        category: '護髮',
        duration: 150,
        description: '抗毛躁護理 • 150 分鐘',
        price: 250
      }
    ],
    reviews: [
      {
        id: 'rev1',
        reviewerName: 'Sarah Jenkins',
        reviewerAvatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCCPmAheQKJVamdFvZuMSrOwzz-hTst9fO_ohnBNF20VM3ozWXdJ0tSYqV5Ayl6FSXVnhn6C7k547wmTIXODb8BgK0Gi4iTgMKAGtZ5Buw86jUNSIfvb15m_xaH754TjL8gxprHrCOgmbtn3seFrVhXgrNbDQkX6LVpl1vuhow2pApC8ZzkNOweOfxY1wRpInBg1sx190HH0HX30L0O6W6zDS7bQJW2fJm-_Q7iwkxoQlqKyNmL_m-MzHmpTkvgh0StnK15zL8MZHI',
        text: 'Leo 絕對是這方面的專家。他為我做的挑染是我見過最自然的。強烈推薦！',
        stars: 5,
        timeAgo: '2 天前',
        images: ['https://lh3.googleusercontent.com/aida-public/AB6AXuARv9m60Y0VIKO3AM-F_TMdfcYhljMZgzocxBu49KdZNqTklOdbw1cCedTEF5PLoEoQ-QCJaQjkUH7CRTjd7zyAMnCIY0OxEs1R1NhW_x6ijgcsBUuPAv8wQWrDex7RK2YhuPW5v8hNquOLKF89vQwXntafbBvHE1TW6aci4hTwguUj7eHh5tCJAT_VFt0mbktM8jDAw_MRf2y3H3FcMURYzZsT544dDrkA6D3W5epHnSynQWF4VloA5r0FUYwojYk5CXvnhZ4VZMA']
      },
      {
        id: 'rev2',
        reviewerName: 'Michael R.',
        reviewerAvatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBeRyOmy4bpeM3RSYCNXKEi5c0srz3K5IbYZksNqKeaug9YL1X4Yzk2YYKZpxuygm1CIe8_I5CgguzLhZSkNrUSXCBh8_xqW9NvZgwFKuCcIpwsjFl1sk6kOSaZRgLsH3IkaTymYj9hmGXSYdfFySYou_526CmXjdoB-_QbElaLzKsuk6635WLb0pw-ouUhtndnl_XT5ucsbxDKxHp4kMj_il5kk1FHdkonvRm_gE3d_AZLP1RQqzfMN04KlKaveVgV8Uj9uk2gSkE',
        text: '全市最好的剪髮體驗，沒有之一。服務專業，環境也很棒。',
        stars: 5,
        timeAgo: '1 週前'
      }
    ]
  },
  {
    id: 'alex-chen',
    name: 'Alex Chen',
    title: '歐美挑染專家',
    rating: 4.9,
    reviewsCount: 96,
    languages: '中 / 粵 / 英',
    experience: '8年資歷',
    specialties: ['歐美挑染', '漸層推剪'],
    avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCu_Du5MDrsjGbQCER4AfBOekSJT7RYGFxPh9Rncm93jQ6GCLA2lApJ6jKcHp5GQR3SG3KORkr9Iv_p6Twe_HTboWytRwfYczlsBhBdEgUdTDcYyGHYdBbwDltRswa45QONk4w6H23c31446NETuHYmaPhZbSj4jsE-jybWeVY2oPZsdYU6ZhnjGkiJjFyYGJhLHD7OZ0EJwgjlbHPVo7d4j_64sS5-COFKmII4jsqMzBNKrCVVxLbhbQTWMwg6ECfEaJ3VI6Mx77c',
    works: [
      {
        id: 'w3',
        title: '冷灰色歐美畫染',
        imageUrl: 'https://images.unsplash.com/photo-1595959183075-c1d0a174db24?auto=format&fit=crop&w=600&q=80'
      },
      {
        id: 'w4',
        title: '復古清爽油頭',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDlNSboCB_LPxPyFQTDFM9AEOOHcj9F4Dp9mXvFKod_jFuRX6OWJzn4xQQNDv1XuYDovw296jBa947P8pAB5ULQcw3wGQh5tmkzzPijSqcumikD4KrBEs1aOl1uWUnJV7_vMUBhhC5eWsdvTWrg_LJG6GJA27GrYmcDNcA-qwX6C61CjiIyTnf4GbFXcjPfSmW8KzlZXrinFG5wa_a6GTBTTQKaBFzocjyiNtiqd1QC1jM44xkt9iRrPdRwjgRX6S3aMxp4LIJAqy8'
      }
    ],
    services: [
      {
        id: 's_alex_cut',
        name: '男士俐落剪髮',
        category: '剪髮',
        duration: 45,
        description: '專業頭骨修飾剪裁含精緻洗髮 • 45 分鐘',
        price: 60
      },
      {
        id: 's_alex_dye',
        name: '巴黎手刷漸層染 (Balayage)',
        category: '染髮',
        duration: 180,
        description: '進口無氨漂色及專屬調色護理 • 180 分鐘',
        price: 280
      }
    ],
    reviews: [
      {
        id: 'rev_ac1',
        reviewerName: 'Jimmy Law',
        reviewerAvatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCCPmAheQKJVamdFvZuMSrOwzz-hTst9fO_ohnBNF20VM3ozWXdJ0tSYqV5Ayl6FSXVnhn6C7k547wmTIXODb8BgK0Gi4iTgMKAGtZ5Buw86jUNSIfvb15m_xaH754TjL8gxprHrCOgmbtn3seFrVhXgrNbDQkX6LVpl1vuhow2pApC8ZzkNOweOfxY1wRpInBg1sx190HH0HX30L0O6W6zDS7bQJW2fJm-_Q7iwkxoQlqKyNmL_m-MzHmpTkvgh0StnK15zL8MZHI',
        text: 'Alex剪油頭非常細緻，兩側漸層推剪無可挑剔，真不愧是專家！',
        stars: 5,
        timeAgo: '3 天前'
      }
    ]
  },
  {
    id: 'sarah-lin',
    name: 'Sarah Lin',
    title: '韓式燙髮專家',
    rating: 4.8,
    reviewsCount: 112,
    languages: '中 / 韓',
    experience: '6年資歷',
    specialties: ['韓式燙髮', '縮毛矯正', '女神大波浪'],
    avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA2h4JuwgbNzzuI2UaQka2FHv2sYfnNhjxvyy9PWAqCTTm6xQue4Op9eDPI0qwbCkFlC_oeCY8MoHnp16g_VUIvEO353N-aLi-hkJQmPi42cjvkRJhxcSFzXTbyjLGbcaVO17REeqWn1-cU7BLhOydD_dnsF782vtKqzJXrP4T3bgIEpzkp1yOJqCF1vHPzBlKTNWUGLHa-7fZUqJ9w-BXqLUZvdUICWYzBOobToXjSWD8UTaiKsneyWMwRs_FqIQTgdJC_RNacDK8',
    works: [
      {
        id: 'w5',
        title: '女神木馬卷',
        imageUrl: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=600&q=80'
      },
      {
        id: 'w6',
        title: '法式外翻氣墊燙',
        imageUrl: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=600&q=80'
      }
    ],
    services: [
      {
        id: 's_sarah_perm',
        name: '韓系高層次氣墊燙',
        category: '燙髮',
        duration: 150,
        description: '客製化澎潤修飾燙，含洗剪保養 • 150 分鐘',
        price: 220
      },
      {
        id: 's_sarah_dye',
        name: '女神霧感拿鐵色染髮',
        category: '染髮',
        duration: 120,
        description: '韓系低調顯白拿鐵棕色，含深層水療 • 120 分鐘',
        price: 130
      }
    ],
    reviews: [
      {
        id: 'rev_sl1',
        reviewerName: '陳詩妤',
        reviewerAvatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAP5t7_veZJCnVdQ4mzpjhL58idf2dJSg9Ai8P-PklgXyTZeb_YtpfknnoQaQYVKz3RVMksFxJB7SkClPMq-C__xZVJ89e6XQotpwXUTEDPpCbcuXX3cVapRcnX1WjObBc7X25hHCpwhBpGoZ7apn40TJDug8U9p4qfwp7EVfTrd3T5ivLYOAdVn5y1k3C6KmqZ-5dwDVtxDQjCYWUK3MQ1HZ2YFY9_KNYfGerD7uI1fCF9UnHDBjtmpsrkGvZ5amLwlzQNVp39y3s',
        text: 'Sarah設計的氣墊燙超棒，回家吹乾用手繞一下就能成型，非常自然！',
        stars: 5,
        timeAgo: '4 天前'
      }
    ]
  },
  {
    id: 'jessica-ho',
    name: 'Jessica Ho',
    title: '縮毛矯正專家',
    rating: 5.0,
    reviewsCount: 78,
    languages: '中 / 粵',
    experience: '5年資歷',
    specialties: ['縮毛矯正', '深層護理', '直髮柔順'],
    avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAP5t7_veZJCnVdQ4mzpjhL58idf2dJSg9Ai8P-PklgXyTZeb_YtpfknnoQaQYVKz3RVMksFxJB7SkClPMq-C__xZVJ89e6XQotpwXUTEDPpCbcuXX3cVapRcnX1WjObBc7X25hHCpwhBpGoZ7apn40TJDug8U9p4qfwp7EVfTrd3T5ivLYOAdVn5y1k3C6KmqZ-5dwDVtxDQjCYWUK3MQ1HZ2YFY9_KNYfGerD7uI1fCF9UnHDBjtmpsrkGvZ5amLwlzQNVp39y3s',
    works: [
      {
        id: 'w7',
        title: '極致直順縮毛矯正',
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuALMG6IuORD20_YRL136IveAbuUDQ4puGdA31CWgtUKqEoIGsYwwfZy_ywbEFv35ei2DUqjdYzsDG8-T0TjCXntB5L9azEhVFV6206QSap1XodMPh2zVDJtZ_ThWiUi6BpLzGNXrbxGLqG4FbbelIroTHwPTIJkgsqTFXe8nEF4oard7Zen6kdnvI09nYsA25a2rukX4ZfIR_yQTzIP83Bi405HAZAe264EL7oYUvB7GYqbXcUAkS-SKBuWe8mqpsnq03wrSXqCxj4'
      }
    ],
    services: [
      {
        id: 's_jess_stra',
        name: '膠原蛋白縮毛矯正',
        category: '直髮',
        duration: 180,
        description: '拯救自然捲與毛躁，恢復鏡面絲滑質感 • 180 分鐘',
        price: 320
      },
      {
        id: 's_jess_treat',
        name: '黑曜光五劑式深層修復',
        category: '護髮',
        duration: 90,
        description: '重建髮絲內部鏈鍵，針對極度受損髮 • 90 分鐘',
        price: 180
      }
    ],
    reviews: [
      {
        id: 'rev_jh1',
        reviewerName: 'Karen Chan',
        reviewerAvatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCCPmAheQKJVamdFvZuMSrOwzz-hTst9fO_ohnBNF20VM3ozWXdJ0tSYqV5Ayl6FSXVnhn6C7k547wmTIXODb8BgK0Gi4iTgMKAGtZ5Buw86jUNSIfvb15m_xaH754TjL8gxprHrCOgmbtn3seFrVhXgrNbDQkX6LVpl1vuhow2pApC8ZzkNOweOfxY1wRpInBg1sx190HH0HX30L0O6W6zDS7bQJW2fJm-_Q7iwkxoQlqKyNmL_m-MzHmpTkvgh0StnK15zL8MZHI',
        text: '終於拯救了我的稻草頭！做完矯正頭髮真的像瀑布一樣柔順且完全不扁塌！',
        stars: 5,
        timeAgo: '2天前'
      }
    ]
  }
];

export const inspirationFeed = [
  {
    id: 'feed1',
    title: '銀灰精靈短髮',
    salon: "Julian's Studio",
    location: '倫敦，梅費爾',
    tags: ['銀灰髮', '短髮造型'],
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB8TJ8Ch99M3t-mCnL3ioJQm9HGnup7pP126tSPGvEtKczY_MzwMw9uWsWcybIaBtCS3Y9OOg5ZGNd5h8v5N25hh3CbzlqL4JnRcINOVo8oIfrmOjDqL3FsK1mZxx4-JhMae7mk1aX7BhrAjR8QYu9DDdFnsQ0M1xT43EygbQlmauT2dophln45Kj_iOufmf-1zZd3bEqlZZhhE6-mhLKY6qaG-rPzzeu0y2Lmeauoxm-sfXTIL_CbprVRKw-NLBdVkmqWJrHFljWs',
    category: '熱門趨勢'
  },
  {
    id: 'feed2',
    title: '琥珀銅漸層染',
    salon: 'Luxe Curls',
    location: '紐約，蘇活區',
    tags: ['琥珀銅色', '歐美手刷染'],
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCM5_1BOrvKr9WyvI5hnQl8AwaFcaoGYb4TewKY-S9aKRgnSqFR3N2ULB-bjKehzWxCBB_G4jwrpugL23NUQjN3XlNAZuIbpc74P07n2-ERRTZXYYE4_-JAyzI4UzqPAVfPIZOjR339JNuzFMutyYZktLxjbAx5BMFn9sHeQr1sLEcS4M3M3J22aSj-h0d-nYSvbl6AVuX-dcqP2x2nxDkhVrjDJlbn-jASXm4LwuA_-iVVrPyyjAenIbqwPa82p7Lq-Ui0efB0knw',
    category: '熱門趨勢'
  },
  {
    id: 'feed3',
    title: '質感漸層油頭',
    salon: 'The Razor Room',
    location: '紐約，布魯克林',
    tags: ['漸層推剪', '男士理髮'],
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDlNSboCB_LPxPyFQTDFM9AEOOHcj9F4Dp9mXvFKod_jFuRX6OWJzn4xQQNDv1XuYDovw296jBa947P8pAB5ULQcw3wGQh5tmkzzPijSqcumikD4KrBEs1aOl1uWUnJV7_vMUBhhC5eWsdvTWrg_LJG6GJA27GrYmcDNcA-qwX6C61CjiIyTnf4GbFXcjPfSmW8KzlZXrinFG5wa_a6GTBTTQKaBFzocjyiNtiqd1QC1jM44xkt9iRrPdRwjgRX6S3aMxp4LIJAqy8',
    category: '熱門趨勢'
  },
  {
    id: 'feed4',
    title: '摩登法式鮑伯',
    salon: 'Parisian Chic',
    location: '巴黎，瑪黑區',
    tags: ['經典鮑伯', '精緻剪裁'],
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuALMG6IuORD20_YRL136IveAbuUDQ4puGdA31CWgtUKqEoIGsYwwfZy_ywbEFv35ei2DUqjdYzsDG8-T0TjCXntB5L9azEhVFV6206QSap1XodMPh2zVDJtZ_ThWiUi6BpLzGNXrbxGLqG4FbbelIroTHwPTIJkgsqTFXe8nEF4oard7Zen6kdnvI09nYsA25a2rukX4ZfIR_yQTzIP83Bi405HAZAe264EL7oYUvB7GYqbXcUAkS-SKBuWe8mqpsnq03wrSXqCxj4',
    category: '熱門趨勢'
  }
];

export const initialBookings: Booking[] = [
  {
    id: 'b1',
    salonName: '銅鑼灣旗艦店 - Zenith Salon',
    stylistName: 'Marcus Lee',
    date: '2026-10-24',
    timeSlot: '14:30 - 16:00',
    serviceName: '深層修剪 & 頭皮護理',
    price: 680,
    status: 'upcoming'
  }
];

export const initialMessages: ChatMessage[] = [
  {
    id: 'm1',
    senderId: 'stylist',
    senderName: 'Master Leo',
    text: '您好！我是 Master Leo。很高興能為您服務。請問今天想諮詢什麼樣的髮型調整呢？',
    time: '09:41'
  },
  {
    id: 'm2',
    senderId: 'user',
    senderName: 'Alex',
    text: '你好，我想嘗試最近流行的巴黎畫染 (Balayage)，但不確定我的髮質是否適合。',
    time: '09:45'
  },
  {
    id: 'm3',
    senderId: 'stylist',
    senderName: 'Master Leo',
    text: '巴黎畫染非常適合增加頭髮的層次感。為了能給您更精確的建議，可以請您上傳一張您目前的頭髮近照嗎？特別是髮尾的受損狀況與目前的髮色。',
    time: '09:46'
  }
];
