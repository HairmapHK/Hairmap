import Foundation

enum SeedData {
    static let salons: [Salon] = [
        Salon(
            id: "s1",
            name: "Maison de Beauté",
            location: "尖沙咀海港城",
            distance: 0.5,
            rating: 5.0,
            tags: ["歐美染髮", "手刷染"],
            openHours: "10:00 - 20:00",
            phone: "+852 2345 6789",
            startPrice: 1200,
            imageURL: "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1200&q=80"
        ),
        Salon(
            id: "s2",
            name: "Noir Studio",
            location: "中環國際金融中心",
            distance: 1.2,
            rating: 4.8,
            tags: ["男士理髮", "英式油頭", "漸層推剪"],
            openHours: "11:00 - 21:00",
            phone: "+852 9876 5432",
            startPrice: 800,
            imageURL: "https://images.unsplash.com/photo-1522338242992-e1a54906a8da?auto=format&fit=crop&w=1200&q=80"
        ),
        Salon(
            id: "s3",
            name: "Zenith Premium Salon",
            location: "銅鑼灣時代廣場",
            distance: 1.8,
            rating: 4.9,
            tags: ["韓式燙髮", "縮毛矯正", "女神大波浪"],
            openHours: "10:00 - 21:00",
            phone: "+852 2882 1122",
            startPrice: 1500,
            imageURL: "https://images.unsplash.com/photo-1633681926022-84c23e8cb2d6?auto=format&fit=crop&w=1200&q=80"
        ),
        Salon(
            id: "s4",
            name: "Elysian Hair Art",
            location: "旺角朗豪坊",
            distance: 2.3,
            rating: 4.7,
            tags: ["裙擺染", "線條感挑染", "深層護理"],
            openHours: "11:00 - 22:00",
            phone: "+852 2772 3344",
            startPrice: 500,
            imageURL: "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=1200&q=80"
        )
    ]

    static let services: [ServiceItem] = [
        ServiceItem(id: "s_cut", stylistID: "master-leo", name: "招牌剪髮", category: "剪髮", duration: 60, description: "含洗髮與造型", price: 80),
        ServiceItem(id: "s_color", stylistID: "master-leo", name: "全頭染髮與光澤護理", category: "染髮", duration: 120, description: "頂級有機染劑", price: 150),
        ServiceItem(id: "s_spa", stylistID: "master-leo", name: "巴西生命果護髮", category: "護髮", duration: 150, description: "抗毛躁深層護理", price: 250),
        ServiceItem(id: "s_alex_cut", stylistID: "alex-chen", name: "男士俐落剪髮", category: "剪髮", duration: 45, description: "頭骨修飾剪裁含精緻洗髮", price: 520),
        ServiceItem(id: "s_alex_dye", stylistID: "alex-chen", name: "巴黎手刷漸層染", category: "染髮", duration: 180, description: "進口無氨漂色及調色護理", price: 1680),
        ServiceItem(id: "s_sarah_perm", stylistID: "sarah-lin", name: "韓系高層次氣墊燙", category: "燙髮", duration: 150, description: "客製澎潤修飾燙含洗剪保養", price: 1480),
        ServiceItem(id: "s_sarah_dye", stylistID: "sarah-lin", name: "女神霧感拿鐵色染髮", category: "染髮", duration: 120, description: "韓系低調顯白色調含水療", price: 980),
        ServiceItem(id: "s_jess_stra", stylistID: "jessica-ho", name: "膠原蛋白縮毛矯正", category: "直髮", duration: 180, description: "恢復鏡面絲滑質感", price: 1880),
        ServiceItem(id: "s_jess_treat", stylistID: "jessica-ho", name: "黑曜光五劑式深層修復", category: "護髮", duration: 90, description: "重建髮絲內部鏈鍵", price: 920)
    ]

    static let works: [PortfolioWork] = [
        PortfolioWork(id: "w1", stylistID: "master-leo", title: "金色巴黎畫染", imageURL: "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=900&q=80"),
        PortfolioWork(id: "w2", stylistID: "master-leo", title: "精準漸層剪裁", imageURL: "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=900&q=80"),
        PortfolioWork(id: "w3", stylistID: "alex-chen", title: "冷灰色歐美畫染", imageURL: "https://images.unsplash.com/photo-1595959183075-c1d0a174db24?auto=format&fit=crop&w=900&q=80"),
        PortfolioWork(id: "w4", stylistID: "alex-chen", title: "復古清爽油頭", imageURL: "https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=900&q=80"),
        PortfolioWork(id: "w5", stylistID: "sarah-lin", title: "女神木馬卷", imageURL: "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=900&q=80"),
        PortfolioWork(id: "w6", stylistID: "sarah-lin", title: "法式外翻氣墊燙", imageURL: "https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=900&q=80"),
        PortfolioWork(id: "w7", stylistID: "jessica-ho", title: "極致直順縮毛矯正", imageURL: "https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?auto=format&fit=crop&w=900&q=80")
    ]

    static let reviews: [ReviewItem] = [
        ReviewItem(id: "rev1", stylistID: "master-leo", reviewerName: "Sarah Jenkins", reviewerAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80", text: "Leo 的挑染非常自然，層次像雜誌封面一樣精緻。", stars: 5, timeAgo: "2 天前"),
        ReviewItem(id: "rev2", stylistID: "master-leo", reviewerName: "Michael R.", reviewerAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80", text: "服務專業，環境安靜，剪完後線條乾淨很多。", stars: 5, timeAgo: "1 週前"),
        ReviewItem(id: "rev3", stylistID: "alex-chen", reviewerName: "Jimmy Law", reviewerAvatar: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80", text: "兩側漸層推剪非常細，油頭比例剛好。", stars: 5, timeAgo: "3 天前"),
        ReviewItem(id: "rev4", stylistID: "sarah-lin", reviewerName: "陳詩妤", reviewerAvatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80", text: "氣墊燙很自然，回家手繞吹乾就能成型。", stars: 5, timeAgo: "4 天前"),
        ReviewItem(id: "rev5", stylistID: "jessica-ho", reviewerName: "Karen Chan", reviewerAvatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80", text: "做完矯正後非常柔順，又不會扁塌。", stars: 5, timeAgo: "2 天前")
    ]

    static var stylists: [Stylist] {
        [
            Stylist(
                id: "master-leo",
                salonID: "s1",
                name: "Master Leo",
                title: "首席設計師",
                rating: 4.9,
                reviewsCount: 124,
                languages: "中 / 英 / 粵",
                experience: "10年以上",
                specialties: ["挑染專家", "經典剪髮"],
                avatarURL: "https://images.unsplash.com/photo-1615109398623-88346a601842?auto=format&fit=crop&w=900&q=80",
                bio: "10年以上明星美髮經驗。擅長巴黎 Balayage 手刷漸層挑染、高精密層次剪裁與修飾臉型氣墊燙。",
                basePrice: 80,
                works: works.filter { $0.stylistID == "master-leo" },
                services: services.filter { $0.stylistID == "master-leo" },
                reviews: reviews.filter { $0.stylistID == "master-leo" }
            ),
            Stylist(
                id: "alex-chen",
                salonID: "s2",
                name: "Alex Chen",
                title: "歐美挑染專家",
                rating: 4.9,
                reviewsCount: 96,
                languages: "中 / 粵 / 英",
                experience: "8年資歷",
                specialties: ["歐美挑染", "漸層推剪"],
                avatarURL: "https://images.unsplash.com/photo-1556157382-97eda2d62296?auto=format&fit=crop&w=900&q=80",
                bio: "專精歐美手刷染與男士輪廓剪裁，重視比例、髮流與日常整理便利度。",
                basePrice: 520,
                works: works.filter { $0.stylistID == "alex-chen" },
                services: services.filter { $0.stylistID == "alex-chen" },
                reviews: reviews.filter { $0.stylistID == "alex-chen" }
            ),
            Stylist(
                id: "sarah-lin",
                salonID: "s3",
                name: "Sarah Lin",
                title: "韓式燙髮專家",
                rating: 4.8,
                reviewsCount: 112,
                languages: "中 / 韓",
                experience: "6年資歷",
                specialties: ["韓式燙髮", "縮毛矯正", "女神大波浪"],
                avatarURL: "https://images.unsplash.com/photo-1580618672591-eb180b1a973f?auto=format&fit=crop&w=900&q=80",
                bio: "擅長韓系柔霧髮色與高層次氣墊燙，喜歡把客人的日常穿搭和臉型一起納入設計。",
                basePrice: 980,
                works: works.filter { $0.stylistID == "sarah-lin" },
                services: services.filter { $0.stylistID == "sarah-lin" },
                reviews: reviews.filter { $0.stylistID == "sarah-lin" }
            ),
            Stylist(
                id: "jessica-ho",
                salonID: "s4",
                name: "Jessica Ho",
                title: "縮毛矯正專家",
                rating: 5.0,
                reviewsCount: 78,
                languages: "中 / 粵",
                experience: "5年資歷",
                specialties: ["縮毛矯正", "深層護理", "直髮柔順"],
                avatarURL: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=900&q=80",
                bio: "專注受損髮修復、直髮柔順與自然捲管理，讓護理後的質感保持可維護。",
                basePrice: 920,
                works: works.filter { $0.stylistID == "jessica-ho" },
                services: services.filter { $0.stylistID == "jessica-ho" },
                reviews: reviews.filter { $0.stylistID == "jessica-ho" }
            )
        ]
    }

    static let inspiration: [InspirationItem] = [
	        InspirationItem(id: "feed1", stylistID: "master-leo", title: "銀灰精靈短髮", salonName: "Maison de Beauté", location: "尖沙咀", tags: ["銀灰髮", "短髮造型"], imageURL: "https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=900&q=80", category: "熱門趨勢"),
        InspirationItem(id: "feed2", stylistID: "alex-chen", title: "琥珀銅漸層染", salonName: "Noir Studio", location: "中環", tags: ["琥珀銅色", "歐美手刷染"], imageURL: "https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=900&q=80", category: "熱門趨勢"),
        InspirationItem(id: "feed3", stylistID: "alex-chen", title: "質感漸層油頭", salonName: "Noir Studio", location: "中環", tags: ["漸層推剪", "男士理髮"], imageURL: "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=900&q=80", category: "最新髮型"),
        InspirationItem(id: "feed4", stylistID: "sarah-lin", title: "摩登法式鮑伯", salonName: "Zenith Premium Salon", location: "銅鑼灣", tags: ["經典鮑伯", "精緻剪裁"], imageURL: "https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=900&q=80", category: "關注中"),
        InspirationItem(id: "feed5", stylistID: "jessica-ho", title: "鏡面柔順直髮", salonName: "Elysian Hair Art", location: "旺角", tags: ["縮毛矯正", "柔順護理"], imageURL: "https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?auto=format&fit=crop&w=900&q=80", category: "最新髮型"),
	        InspirationItem(id: "feed6", stylistID: "master-leo", title: "巴黎手刷層次", salonName: "Maison de Beauté", location: "尖沙咀", tags: ["Balayage", "層次染"], imageURL: "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=900&q=80", category: "熱門趨勢")
    ]

    static let sharedLooks: [SharedHairLook] = [
        SharedHairLook(
            id: "seed_silver_pixie",
            title: "銀灰精靈短髮",
            author: "Julian's Studio",
            studio: "Julian's Studio",
            tags: ["#銀灰髮", "#短髮造型"],
            imageURL: "https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=900&q=80",
            mediaData: nil,
            mediaKind: .photo,
            stylistID: "master-leo",
            faceShape: "鵝蛋臉、圓臉皆適合",
            hairType: "細軟髮至中等髮量",
            specs: "造型前使用輕霧感髮泥，保持髮根蓬鬆。",
            details: "俐落短髮線條配合銀灰霧感，適合想要清爽但有辨識度的造型。",
            likes: 12,
            category: "熱門趨勢",
            isUserPost: false
        ),
        SharedHairLook(
            id: "seed_amber_copper",
            title: "琥珀銅漸層染",
            author: "Luxe Curls",
            studio: "Luxe Curls",
            tags: ["#琥珀銅色", "#歐美手刷染"],
            imageURL: "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=900&q=80",
            mediaData: nil,
            mediaKind: .photo,
            stylistID: "alex-chen",
            faceShape: "長臉、心形臉適合",
            hairType: "中等或偏厚髮量",
            specs: "每週使用護色洗髮水，避免高溫過度吹整。",
            details: "暖銅色和柔光捲度能增加髮絲立體感，日光下特別顯色。",
            likes: 19,
            category: "熱門趨勢",
            isUserPost: false
        )
    ]

    static let bookings: [Appointment] = [
        Appointment(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            customerID: nil,
            stylistID: "master-leo",
            salonID: "s1",
            serviceID: "s_color",
	            salonName: "Maison de Beauté",
            stylistName: "Master Leo",
            clientName: "Alex Chen",
            clientPhone: "+852 6123 4567",
            bookingDate: "2026-10-24",
            startTime: "14:30",
            endTime: "16:30",
            serviceName: "全頭染髮與光澤護理",
            price: 1280,
            status: .pending
        )
    ]

    static let messages: [ChatMessageItem] = [
        ChatMessageItem(id: "m1", customerID: nil, stylistID: "master-leo", senderRole: .stylist, senderName: "Master Leo", text: "您好！我是 Master Leo。很高興能為您服務，今天想諮詢什麼髮型調整呢？", sentAt: "09:41"),
        ChatMessageItem(id: "m2", customerID: nil, stylistID: "master-leo", senderRole: .customer, senderName: "Alex", text: "我想嘗試巴黎畫染，但不確定髮質是否適合。", sentAt: "09:45"),
        ChatMessageItem(id: "m3", customerID: nil, stylistID: "master-leo", senderRole: .stylist, senderName: "Master Leo", text: "巴黎畫染非常適合增加頭髮的層次感與立體線條！為了能給您更精準的建議，可以請您上傳一張您目前的髮型近照嗎？", sentAt: "12:09"),
        ChatMessageItem(id: "m4", customerID: nil, stylistID: "alex-chen", senderRole: .stylist, senderName: "Alex Chen", text: "這很常見！亞洲人髮質偏硬，側邊特別容易橫向炸開。我會建議以低漸層搭配霧感髮泥整理。", sentAt: "昨日 15:45"),
        ChatMessageItem(id: "m5", customerID: nil, stylistID: "alex-chen", senderRole: .customer, senderName: "Alex", text: "我想要清爽油頭，但不要太正式，可以自然一點嗎？", sentAt: "昨日 15:52"),
        ChatMessageItem(id: "m6", customerID: nil, stylistID: "sarah-lin", senderRole: .stylist, senderName: "Sarah Lin", text: "完全不會！我會特別在額角兩側設計「法式八字瀏海」，讓臉型比例更柔和。", sentAt: "星期三 10:22"),
        ChatMessageItem(id: "m7", customerID: nil, stylistID: "jessica-ho", senderRole: .stylist, senderName: "Jessica Ho", text: "您好！我是 Jessica。我專精縮毛矯正和深層重塑護理，可以先了解您的髮尾受損程度嗎？", sentAt: "星期一 11:28")
    ]

    static let blockedSlots: [BlockedSlot] = [
        BlockedSlot(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, stylistID: "master-leo", workDate: "2026-06-08", startTime: "12:00"),
        BlockedSlot(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, stylistID: "master-leo", workDate: "2026-06-08", startTime: "13:00")
    ]

    static var catalog: CatalogPayload {
        CatalogPayload(
            salons: salons,
            stylists: stylists,
            inspiration: inspiration,
            bookings: bookings,
            messages: messages,
            blockedSlots: blockedSlots
        )
    }
}
