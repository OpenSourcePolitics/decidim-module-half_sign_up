$(() => {
    console.log("Hello")
    console.log($("#sms_auth_phone_country").val())

    const updateButtonState = () => {
        if ($("#sms_auth_phone_country").val() === "FR") {
            $(".button").prop("disabled", true);
            console.log("change to FR works");

            $("#sms_auth_phone_number").on('input', function() {
                const phoneNumber = $(this).val();
                if ((phoneNumber.charAt(0) === "0" && phoneNumber.length === 10) || (phoneNumber.charAt(0) !== "0" && phoneNumber.length === 9)) {
                    console.log(phoneNumber);
                    console.log(phoneNumber.charAt(0));
                    console.log(typeof (phoneNumber));
                    console.log(phoneNumber.length);
                    $(".button").prop("disabled", false);
                    const regex = /^(0[67]|[67])\d{8}$/;

                    if (regex.test(phoneNumber)) {
                        console.log("valid number");
                        // $(".button").prop("disabled", false);
                    } else {
                        console.log("unvalid number");
                        $('#form-error').show();
                    }
                } else {
                    $(".button").prop("disabled", true);
                }
            });

        } else {
                    $(".button").prop("disabled", false);
                }
    };

    updateButtonState()

    $("#sms_auth_phone_country").change( function(){
        console.log($("#sms_auth_phone_country").val())

        updateButtonState()
    })
})

